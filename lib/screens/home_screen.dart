import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(context, listen: false).loadQuestions();
      Provider.of<AuthProvider>(context, listen: false).fetchAssessment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RTO Smart Prep', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome, ${authProvider.name ?? 'User'}!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              if (authProvider.isLoading)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (authProvider.stats != null)
                 _buildAssessmentCard(context, authProvider.stats!)
              else
                 const Card(
                   child: Padding(
                     padding: EdgeInsets.all(20.0),
                     child: Center(child: Text("No assessment data available.")),
                   ),
                 ),
              
              const SizedBox(height: 24),
              _buildFeatureCard(
                context,
                title: 'Traffic Rules',
                description: 'Learn important driving rules and regulations.',
                icon: Icons.rule,
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/rules'),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                title: 'Traffic Signs',
                description: 'Identify and understand common traffic signs.',
                icon: Icons.traffic,
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, '/signs'),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                  quizProvider.startQuiz();
                  Navigator.pushNamed(context, '/quiz');
                },
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text('Start Quiz', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'Recent Quiz History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (authProvider.history != null && authProvider.history!.isNotEmpty)
                _buildHistoryList(authProvider.history!)
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No quizzes taken yet.', style: TextStyle(fontStyle: FontStyle.italic)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context, Map<String, dynamic> stats) {
    int totalTests = stats['total_tests'] ?? 0;
    int testsPassed = stats['tests_passed'] != null ? int.parse(stats['tests_passed'].toString()) : 0;
    int bestScore = stats['best_score'] ?? 0;
    double avgScore = stats['average_score'] != null ? double.parse(stats['average_score'].toString()) : 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Overall Assessment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _statColumn('Total Quizzes', '$totalTests')),
                Expanded(child: _statColumn('Passed', '$testsPassed', color: Colors.green)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _statColumn('Best Score', '$bestScore', color: Colors.blue)),
                Expanded(child: _statColumn('Avg Score', avgScore.toStringAsFixed(1), color: Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _statColumn(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required String title, required String description, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(description, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<dynamic> history) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final isPass = item['result'] == 'PASS';
        
        DateTime date;
        try {
          date = DateTime.parse(item['created_at']);
        } catch (e) {
          date = DateTime.now();
        }
        
        final dateStr = "${date.day}/${date.month}/${date.year}";

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPass ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              child: Icon(
                isPass ? Icons.check_circle : Icons.cancel,
                color: isPass ? Colors.green : Colors.red,
              ),
            ),
            title: Text('Score: ${item['score']}/${item['total_questions']}'),
            subtitle: Text('Date: $dateStr'),
            trailing: Text(
              '${item['percentage']}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPass ? Colors.green : Colors.red,
                fontSize: 16
              ),
            ),
          ),
        );
      },
    );
  }
}
