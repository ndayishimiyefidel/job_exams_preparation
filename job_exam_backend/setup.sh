#!/bin/bash

# Job Exam System Backend Setup Script
# This script helps set up the backend system

echo "🚀 Job Exam System Backend Setup"
echo "=================================="

# Check if PHP is installed
if ! command -v php &> /dev/null; then
    echo "❌ PHP is not installed. Please install PHP 7.4 or higher."
    exit 1
fi

# Check PHP version
PHP_VERSION=$(php -r "echo PHP_VERSION;")
echo "✅ PHP version: $PHP_VERSION"

# Check if MySQL is accessible
echo "📋 Checking database connection..."
read -p "Enter MySQL host (default: localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Enter MySQL username: " DB_USER
read -s -p "Enter MySQL password: " DB_PASS
echo

read -p "Enter database name (default: job_exam_system): " DB_NAME
DB_NAME=${DB_NAME:-job_exam_system}

# Test database connection
if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" &> /dev/null; then
    echo "✅ Database connection successful"
else
    echo "❌ Database connection failed. Please check your credentials."
    exit 1
fi

# Create database if it doesn't exist
echo "🗄️  Creating database..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

# Import database schema
echo "📥 Importing database schema..."
if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < job_exam_system.sql; then
    echo "✅ Database schema imported successfully"
else
    echo "❌ Failed to import database schema"
    exit 1
fi

# Create database configuration file
echo "⚙️  Creating database configuration..."
cp config/db_connect.example.php config/db_connect.php

# Update database configuration
sed -i "s/your_username/$DB_USER/g" config/db_connect.php
sed -i "s/your_password/$DB_PASS/g" config/db_connect.php
sed -i "s/localhost/$DB_HOST/g" config/db_connect.php
sed -i "s/job_exam_system/$DB_NAME/g" config/db_connect.php

echo "✅ Database configuration updated"

# Create required directories
echo "📁 Creating required directories..."
mkdir -p uploads/resources uploads/questions_bulk cache
chmod 755 uploads uploads/resources uploads/questions_bulk cache

echo "✅ Directories created with proper permissions"

# Test the API
echo "🧪 Testing API..."
if curl -s http://localhost/job_exam_backend/ | grep -q "success"; then
    echo "✅ API is working correctly"
else
    echo "⚠️  API test failed. Make sure your web server is running and pointing to this directory."
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Make sure your web server (Apache/Nginx) is configured to serve this directory"
echo "2. Test the API using Postman (see POSTMAN_TESTING_GUIDE.md)"
echo "3. Default admin credentials:"
echo "   - Email: admin@jobexam.com"
echo "   - Password: admin123"
echo ""
echo "📚 Documentation:"
echo "- README.md - Main documentation"
echo "- POSTMAN_TESTING_GUIDE.md - Testing instructions"
echo "- QUESTION_FORMAT_GUIDE.md - Question format details"
echo ""
echo "🔗 API Base URL: http://localhost/job_exam_backend/"
