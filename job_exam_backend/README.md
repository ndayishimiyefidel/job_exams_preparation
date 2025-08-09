# Job Exam System Backend

A comprehensive backend system for job exam preparation with support for both web admin portal and mobile applications.

## Features

### For Users (Job Seekers)
- Browse job positions and available exams
- Take free exams without registration
- Purchase paid exams via integrated payment gateway
- Practice MCQs with timed or untimed modes
- View detailed results and review missed questions
- Access study resources (PDFs, videos, guides)

### For Admin
- Manage job positions and categories
- Upload questions in bulk via CSV/Excel or individually
- Mark exams as free or paid with pricing
- Upload and manage study resources
- View comprehensive analytics and usage reports
- Track user activity and exam performance

## Technology Stack

- **Backend**: PHP 7.4+ with MySQLi (procedural)
- **Database**: MySQL 5.7+
- **Authentication**: Session-based for web, API tokens for mobile
- **File Upload**: Support for PDFs, images, videos, and documents
- **Caching**: JSON-based question caching for performance

## Installation

### Prerequisites
- PHP 7.4 or higher
- MySQL 5.7 or higher
- Web server (Apache/Nginx)
- PHP extensions: mysqli, json, fileinfo

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/job-exam-system.git
   cd job-exam-system/job_exam_backend
   ```

2. **Configure database connection**
   ```bash
   cp config/db_connect.example.php config/db_connect.php
   ```
   Edit `config/db_connect.php` with your database credentials:
   ```php
   define('DB_HOST', 'localhost');
   define('DB_USER', 'your_username');
   define('DB_PASS', 'your_password');
   define('DB_NAME', 'job_exam_system');
   ```

3. **Import database schema**
   ```bash
   mysql -u your_username -p job_exam_system < job_exam_system.sql
   ```

4. **Set up directories**
   ```bash
   mkdir -p uploads/resources uploads/questions_bulk cache
   chmod 755 uploads uploads/resources uploads/questions_bulk cache
   ```

5. **Default admin credentials**
   - Email: `admin@jobexam.com`
   - Password: `admin123`

## API Endpoints

### Authentication
- `POST /api/auth/login.php` - User login
- `POST /api/auth/register.php` - User registration
- `POST /api/auth/logout.php` - User logout

### Mobile App Endpoints
- `GET /api/positions.php` - Get job positions
- `GET /api/exams.php` - Get exams for a position
- `GET /api/questions.php` - Get exam questions (without answers)
- `POST /api/submit_results.php` - Submit exam results
- `GET /api/resources.php` - Get study resources
- `POST /api/payments.php` - Process payments

### Admin Endpoints
- `POST /admin/positions/create.php` - Create position
- `GET /admin/positions/read.php` - List positions
- `PUT /admin/positions/update.php` - Update position
- `DELETE /admin/positions/delete.php` - Delete position
- `POST /admin/questions/create.php` - Create question
- `POST /admin/questions/upload_bulk.php` - Bulk upload questions
- `GET /admin/questions/read.php` - List questions
- `PUT /admin/exams/mark_free_paid.php` - Mark exam as free/paid
- `GET /admin/analytics/usage.php` - Get analytics

## New Features (Latest Update)

### User Phone Support
- Users can now register with phone numbers
- Phone field is optional during registration
- Supports international phone number formats

### Question Images
- Questions can now include image URLs
- Supports external image hosting (CDN, cloud storage)
- Images are optional and don't affect existing questions

### Migration for Existing Databases
If you have an existing database, run the migration script:
```bash
mysql -u your_username -p job_exam_system < migrate_add_fields.sql
```

## Database Schema

### Core Tables
- `users` - User accounts and authentication
- `positions` - Job positions/categories
- `exams` - Exams linked to positions
- `questions` - Exam questions
- `choices` - Multiple choice options
- `resources` - Study materials
- `payments` - Payment transactions
- `results` - Exam results and scores

### Support Tables
- `question_cache` - Cached questions for performance
- `api_tokens` - Mobile app authentication
- `activity_logs` - Admin activity tracking

## Bulk Question Upload

### CSV Format
Create a CSV file with the following columns:
```
question,choice1,choice2,choice3,choice4,correct_answer
"What is the primary responsibility of a bank teller?","Process customer transactions","Manage the entire bank","Only handle deposits","Only handle withdrawals",1
```

### Excel Format
Same structure as CSV but in Excel format (.xlsx)

## Security Features

- SQL injection prevention with prepared statements
- XSS protection with input sanitization
- CSRF protection for admin forms
- Password hashing with bcrypt
- API token authentication for mobile apps
- File upload validation and sanitization

## Performance Optimizations

- Question caching in JSON format
- Database indexing on frequently queried columns
- Pagination for large datasets
- Optimized queries with proper JOINs

## Mobile App Integration

The backend is designed to support mobile applications with:
- RESTful API endpoints
- JSON responses
- CORS support
- API token authentication
- Offline-capable question caching

## File Structure

```
job_exam_backend/
├── config/
│   └── db_connect.php
├── includes/
│   ├── auth.php
│   └── helpers.php
├── admin/
│   ├── positions/
│   ├── questions/
│   ├── resources/
│   ├── exams/
│   └── analytics/
├── api/
│   ├── auth/
│   ├── positions.php
│   ├── exams.php
│   ├── questions.php
│   ├── submit_results.php
│   ├── resources.php
│   └── payments.php
├── uploads/
│   ├── resources/
│   └── questions_bulk/
├── cache/
├── job_exam_system.sql
├── index.php
└── README.md
```

## Testing

### Postman Testing (Recommended)

1. **Import Postman Collection**
   - Download `Job_Exam_System.postman_collection.json`
   - Import into Postman
   - Set up environment variables (see `POSTMAN_TESTING_GUIDE.md`)

2. **Quick Test with curl**
   ```bash
   # Test API status
   curl http://localhost/job_exam_backend/

   # Test positions endpoint
   curl http://localhost/job_exam_backend/api/positions.php

   # Test admin login
   curl -X POST http://localhost/job_exam_backend/admin/auth/login.php \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@jobexam.com","password":"admin123"}'
   ```

3. **Comprehensive Testing Guide**
   - See `POSTMAN_TESTING_GUIDE.md` for detailed testing instructions
   - Use `sample_questions.csv` for bulk upload testing
   - Follow the testing checklist in the guide

## Troubleshooting

### Common Issues

1. **Database Connection Error**
   - Check database credentials in `config/db_connect.php`
   - Ensure MySQL service is running
   - Verify database exists

2. **File Upload Errors**
   - Check directory permissions (755 for uploads/)
   - Verify PHP file upload settings in php.ini
   - Check file size limits

3. **CORS Issues**
   - Ensure CORS headers are properly set
   - Check if requests include proper headers

4. **Performance Issues**
   - Enable question caching
   - Check database indexes
   - Monitor query performance

## Contributing

1. Follow PSR-4 coding standards
2. Add proper error handling
3. Include input validation
4. Write clear documentation
5. Test thoroughly before submitting

## License

This project is licensed under the MIT License.

## Support

For support and questions:
- Check the documentation
- Review the API endpoints
- Test with the provided sample data
- Contact the development team
