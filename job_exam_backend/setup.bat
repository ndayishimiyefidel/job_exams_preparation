@echo off
REM Job Exam System Backend Setup Script for Windows
REM This script helps set up the backend system

echo 🚀 Job Exam System Backend Setup
echo ==================================

REM Check if PHP is installed
php --version >nul 2>&1
if errorlevel 1 (
    echo ❌ PHP is not installed or not in PATH. Please install PHP 7.4 or higher.
    pause
    exit /b 1
)

REM Get PHP version
for /f "tokens=*" %%i in ('php -r "echo PHP_VERSION;"') do set PHP_VERSION=%%i
echo ✅ PHP version: %PHP_VERSION%

REM Check if MySQL is accessible
echo 📋 Checking database connection...
set /p DB_HOST="Enter MySQL host (default: localhost): "
if "%DB_HOST%"=="" set DB_HOST=localhost

set /p DB_USER="Enter MySQL username: "
set /p DB_PASS="Enter MySQL password: "

set /p DB_NAME="Enter database name (default: job_exam_system): "
if "%DB_NAME%"=="" set DB_NAME=job_exam_system

REM Test database connection
mysql -h "%DB_HOST%" -u "%DB_USER%" -p"%DB_PASS%" -e "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo ❌ Database connection failed. Please check your credentials.
    pause
    exit /b 1
) else (
    echo ✅ Database connection successful
)

REM Create database if it doesn't exist
echo 🗄️  Creating database...
mysql -h "%DB_HOST%" -u "%DB_USER%" -p"%DB_PASS%" -e "CREATE DATABASE IF NOT EXISTS %DB_NAME%;"

REM Import database schema
echo 📥 Importing database schema...
mysql -h "%DB_HOST%" -u "%DB_USER%" -p"%DB_PASS%" "%DB_NAME%" < job_exam_system.sql
if errorlevel 1 (
    echo ❌ Failed to import database schema
    pause
    exit /b 1
) else (
    echo ✅ Database schema imported successfully
)

REM Create database configuration file
echo ⚙️  Creating database configuration...
copy config\db_connect.example.php config\db_connect.php >nul

REM Update database configuration (basic replacement)
powershell -Command "(Get-Content config\db_connect.php) -replace 'your_username', '%DB_USER%' -replace 'your_password', '%DB_PASS%' -replace 'localhost', '%DB_HOST%' -replace 'job_exam_system', '%DB_NAME%' | Set-Content config\db_connect.php"

echo ✅ Database configuration updated

REM Create required directories
echo 📁 Creating required directories...
if not exist "uploads\resources" mkdir uploads\resources
if not exist "uploads\questions_bulk" mkdir uploads\questions_bulk
if not exist "cache" mkdir cache

echo ✅ Directories created

REM Test the API
echo 🧪 Testing API...
curl -s http://localhost/job_exam_backend/ | findstr "success" >nul
if errorlevel 1 (
    echo ⚠️  API test failed. Make sure your web server is running and pointing to this directory.
) else (
    echo ✅ API is working correctly
)

echo.
echo 🎉 Setup completed successfully!
echo.
echo 📋 Next steps:
echo 1. Make sure your web server (Apache/Nginx) is configured to serve this directory
echo 2. Test the API using Postman (see POSTMAN_TESTING_GUIDE.md)
echo 3. Default admin credentials:
echo    - Email: admin@jobexam.com
echo    - Password: admin123
echo.
echo 📚 Documentation:
echo - README.md - Main documentation
echo - POSTMAN_TESTING_GUIDE.md - Testing instructions
echo - QUESTION_FORMAT_GUIDE.md - Question format details
echo.
echo 🔗 API Base URL: http://localhost/job_exam_backend/
echo.
pause
