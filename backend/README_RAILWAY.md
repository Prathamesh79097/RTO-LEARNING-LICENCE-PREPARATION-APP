# Deployment to Railway

This backend is optimized for deployment on [Railway.app](https://railway.app/).

## Railway Dashboard Settings

When creating your service on Railway, ensure you set the following:

1. **Root Directory**: `backend`
   - *Found in: Service Settings > General > Root Directory*
2. **Database**: Add a **MySQL** plugin to your project.
   - Railway will automatically inject `MYSQLHOST`, `MYSQLUSER`, `MYSQLPORT`, etc., which the code is now configured to use.
3. **Environment Variables**:
   - `JWT_SECRET`: (Required) Set a strong random string.
   - `MYSQL_SSL`: Set to `true` if Railway requires SSL for database connections.

## Port
Railway will automatically provide a `PORT` environment variable, which the server will listen on.
