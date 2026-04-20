require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const fs = require('fs');
const path = require('path');

const app = express();

// Security Middlewares
app.use(helmet());
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret';

// Rate Limiter for Login/Register to prevent brute-force
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // Limit each IP to 20 requests per window
  message: { error: 'Too many login attempts, please try again after 15 minutes' }
});

// MySQL Database configuration - Support new and old .env names, plus MYSQL_URL
// MySQL Database configuration - Support new and old .env names, plus MYSQL_URL
const dbConfig = {
  host: process.env.MYSQLHOST || 'localhost',
  user: process.env.MYSQLUSER || 'root',
  password: process.env.MYSQL_ROOT_PASSWORD || process.env.MYSQLPASSWORD || '',
  port: parseInt(process.env.MYSQLPORT || '3306', 10),
  database: process.env.MYSQL_DATABASE || process.env.MYSQLDATABASE || 'rto_app_db'
};

// Prioritize Public URL for local development, fall back to internal URL
const MYSQL_URL = process.env.MYSQL_PUBLIC_URL || process.env.MYSQL_URL || null;

let pool;

async function initDB() {
  try {
    let connection;
    
    // 1. Connection attempt
    if (MYSQL_URL) {
      // If URL is provided, use it
      connection = await mysql.createConnection(MYSQL_URL);
      console.log('Connected using Database URL');
    } else {
      // Fallback to individual config if no URL
      connection = await mysql.createConnection({
        host: dbConfig.host,
        user: dbConfig.user,
        password: dbConfig.password,
        port: dbConfig.port
      });
      await connection.query(`CREATE DATABASE IF NOT EXISTS \`${dbConfig.database}\``);
    }
    
    await connection.end();

    // 2. Create the pool for application-wide use
    pool = mysql.createPool(MYSQL_URL ? {
      uri: MYSQL_URL,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      multipleStatements: true,
      ssl: process.env.MYSQL_SSL ? { rejectUnauthorized: false } : undefined
    } : {
      ...dbConfig,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      multipleStatements: true,
      ssl: process.env.MYSQL_SSL ? { rejectUnauthorized: false } : undefined
    });

    // 3. Automated Seeding: Check if tables exist. If not, seed from database.sql
    const [tables] = await pool.query("SHOW TABLES LIKE 'users'");
    if (tables.length === 0) {
      console.log('Fresh database detected. Attempting to seed from database.sql...');
      const sqlPath = path.join(__dirname, 'database.sql');
      
      if (fs.existsSync(sqlPath)) {
        try {
          const buffer = fs.readFileSync(sqlPath);
          // Check for UTF-16 BOM or character patterns
          const isUtf16 = buffer[0] === 0xff && buffer[1] === 0xfe || buffer.includes(Buffer.from([0, 0]));
          const sql = buffer.toString(isUtf16 ? 'utf16le' : 'utf8');
          
          await pool.query(sql);
          console.log('Database seeded successfully from database.sql.');
        } catch (seedError) {
          console.error('Error during database seeding:', seedError);
          // Don't exit, try to continue with standard table creation below
        }
      } else {
        console.warn('database.sql not found in backend directory. Skipping auto-seed.');
      }
    }

    const createUsersTableQuery = `
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `;
    await pool.query(createUsersTableQuery);

    const createQuizAttemptsTableQuery = `
      CREATE TABLE IF NOT EXISTS quiz_attempts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        score INT NOT NULL,
        total_questions INT NOT NULL DEFAULT 15,
        attempted_questions INT NOT NULL,
        correct_answers INT NOT NULL,
        wrong_answers INT NOT NULL,
        percentage DECIMAL(5,2) NOT NULL,
        result ENUM('PASS', 'FAIL') NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `;
    await pool.query(createQuizAttemptsTableQuery);

    console.log('Successfully connected to MySQL and initialized database.');
  } catch (error) {
    console.error('Failed to initialize database:', error);
    process.exit(1);
  }
}

// Middleware to verify JWT tokens
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Format: "Bearer TOKEN"

  if (!token) return res.status(401).json({ error: 'Access Denied: No Token Provided' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid or Expired Token' });
    req.user = user; 
    next();
  });
}

// ---------------- ROUTES ----------------

app.post('/api/register', authLimiter, async (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email, and password are required' });
  }

  if (name.trim().length < 5) {
    return res.status(400).json({ error: 'Name must be at least 5 characters long' });
  }

  if (!/^[a-zA-Z\s]+$/.test(name)) {
    return res.status(400).json({ error: 'Name can only contain letters and spaces' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [name, email, hashedPassword]
    );
    
    const userId = result.insertId;
    const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '7d' });

    res.json({ success: true, message: 'User registered successfully', userId, token });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Email already exists' });
    }
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/login', authLimiter, async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = rows[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    
    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });

    res.json({ 
      success: true, 
      token,
      user: { 
        id: user.id, 
        name: user.name, 
        email: user.email 
      } 
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Secured Endpoints
app.post('/api/saveQuizResult', authenticateToken, async (req, res) => {
  const { score, attempted, correct, wrong, percentage, result } = req.body;
  const userId = req.user.id; // securely retrieved from valid JWT token

  if (score === undefined) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    await pool.query(
      `INSERT INTO quiz_attempts 
       (user_id, score, total_questions, attempted_questions, correct_answers, wrong_answers, percentage, result) 
       VALUES (?, ?, 15, ?, ?, ?, ?, ?)`,
      [userId, score, attempted, correct, wrong, percentage, result]
    );

    res.json({ success: true, message: 'Quiz result saved successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/getUserResults/:userId', authenticateToken, async (req, res) => {
  // We can enforce that users only get their own results
  if (req.user.id !== parseInt(req.params.userId, 10)) {
     return res.status(403).json({ error: 'Unauthorized to access this data' });
  }
  
  const userId = req.user.id;
  
  try {
    const [statsRows] = await pool.query(`
      SELECT 
        COUNT(*) as total_tests,
        SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) as tests_passed,
        MAX(score) as best_score,
        AVG(score) as average_score
      FROM quiz_attempts 
      WHERE user_id = ?
    `, [userId]);

    const [historyRows] = await pool.query(`
      SELECT * FROM quiz_attempts 
      WHERE user_id = ? 
      ORDER BY created_at DESC 
      LIMIT 10
    `, [userId]);

    res.json({
      success: true,
      stats: statsRows[0],
      history: historyRows
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start Server
initDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Server securely running on http://localhost:${PORT}`);
  });
});
