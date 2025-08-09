# Job Exam System

A comprehensive job exam preparation system with support for both web admin portal and mobile applications. This system allows job seekers to practice exams, purchase paid content, and access study resources, while providing administrators with tools to manage content and track usage.

## 🚀 Features

### For Job Seekers (Mobile/Web App)
- 📱 **Browse Job Positions** - Explore different career categories
- 🆓 **Free Exams** - Practice without registration
- 💳 **Paid Exams** - Purchase premium content via payment gateway
- ⏱️ **Timed/Untimed Practice** - Flexible exam modes
- 📊 **Results & Review** - Detailed performance analysis
- 📚 **Study Resources** - PDFs, videos, guides, and past papers
- 🔄 **Offline Support** - Cached questions for offline practice

### For Administrators (Web Portal)
- 👥 **Position Management** - Create and manage job categories
- 📝 **Question Management** - Individual or bulk upload via CSV/Excel
- 💰 **Pricing Control** - Mark exams as free or paid
- 📁 **Resource Management** - Upload study materials
- 📈 **Analytics Dashboard** - Usage statistics and performance metrics
- 🔍 **Activity Logging** - Track admin actions and user behavior

## 🏗️ Architecture

```
job_exams/
├── job_exam_backend/     # PHP Backend API
│   ├── admin/           # Admin portal endpoints
│   ├── api/             # Mobile app endpoints
│   ├── config/          # Database configuration
│   ├── includes/        # Helper functions
│   └── uploads/         # File storage
└── job_exam_frontend/   # Frontend applications
    ├── admin-portal/    # Web admin interface
    └── mobile-app/      # Mobile application
```

## 🛠️ Technology Stack

### Backend
- **Language**: PHP 7.4+ (MySQLi procedural)
- **Database**: MySQL 5.7+
- **Authentication**: Session-based (admin) + API tokens (mobile)
- **File Handling**: PDF, images, videos, CSV/Excel uploads
- **Caching**: JSON-based question caching
- **Security**: SQL injection prevention, XSS protection, CSRF protection

### Frontend (Planned)
- **Admin Portal**: React.js + Bootstrap
- **Mobile App**: React Native / Flutter
- **Payment Gateway**: Stripe / PayPal integration

## 📦 Installation

### Prerequisites
- PHP 7.4 or higher
- MySQL 5.7 or higher
- Web server (Apache/Nginx)
- PHP extensions: mysqli, json, fileinfo

### Quick Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/job-exam-system.git
   cd job-exam-system
   ```

2. **Backend Setup**
   ```bash
   cd job_exam_backend
   
   # Run setup script (Linux/Mac)
   chmod +x setup.sh
   ./setup.sh
   
   # Or run setup script (Windows)
   setup.bat
   ```

3. **Manual Setup** (if scripts don't work)
   ```bash
   # Copy database configuration
   cp config/db_connect.example.php config/db_connect.php
   
   # Edit with your database credentials
   nano config/db_connect.php
   
   # Import database schema
   mysql -u your_username -p job_exam_system < job_exam_system.sql
   
   # Create directories
   mkdir -p uploads/resources uploads/questions_bulk cache
   chmod 755 uploads uploads/resources uploads/questions_bulk cache
   ```

4. **Default Admin Credentials**
   - Email: `admin@jobexam.com`
   - Password: `admin123`

## 🧪 Testing

### Postman Testing (Recommended)
1. Download `Job_Exam_System.postman_collection.json`
2. Import into Postman
3. Set up environment variables
4. Follow `POSTMAN_TESTING_GUIDE.md`

### Quick API Test
```bash
# Test API status
curl http://localhost/job_exams/job_exam_backend/

# Test admin login
curl -X POST http://localhost/job_exams/job_exam_backend/admin/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@jobexam.com","password":"admin123"}'
```

## 📚 Documentation

- **[Backend README](job_exam_backend/README.md)** - Complete backend documentation
- **[Postman Testing Guide](job_exam_backend/POSTMAN_TESTING_GUIDE.md)** - API testing instructions
- **[Question Format Guide](job_exam_backend/QUESTION_FORMAT_GUIDE.md)** - Question structure details
- **[API Documentation](job_exam_backend/index.php)** - Live API endpoint documentation

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/login.php` - User login
- `POST /api/auth/register.php` - User registration
- `POST /api/auth/logout.php` - User logout

### Mobile App
- `GET /api/positions.php` - Get job positions
- `GET /api/exams.php` - Get exams for position
- `GET /api/questions.php` - Get exam questions
- `POST /api/submit_results.php` - Submit exam results
- `GET /api/resources.php` - Get study resources
- `POST /api/payments.php` - Process payments

### Admin Portal
- `POST /admin/positions/create.php` - Create position
- `GET /admin/positions/read.php` - List positions
- `POST /admin/questions/upload_bulk.php` - Bulk upload questions
- `GET /admin/analytics/usage.php` - Get analytics

## 📊 Database Schema

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

## 🔒 Security Features

- **SQL Injection Prevention** - Prepared statements and input sanitization
- **XSS Protection** - HTML entity encoding
- **CSRF Protection** - Token-based form protection
- **Password Security** - bcrypt hashing
- **API Security** - Token-based authentication
- **File Upload Security** - Type and size validation

## 🚀 Performance Optimizations

- **Question Caching** - JSON-based caching for faster responses
- **Database Indexing** - Optimized queries with proper indexes
- **Pagination** - Efficient handling of large datasets
- **File Compression** - Optimized file storage and delivery

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow PSR-4 coding standards
- Add proper error handling
- Include input validation
- Write clear documentation
- Test thoroughly before submitting

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 **Documentation**: Check the guides in the `job_exam_backend/` directory
- 🐛 **Issues**: Report bugs via GitHub Issues
- 💬 **Discussions**: Use GitHub Discussions for questions
- 📧 **Email**: Contact the development team

## 🗺️ Roadmap

### Phase 1: Backend (✅ Complete)
- [x] Core API endpoints
- [x] Authentication system
- [x] Question management
- [x] Payment processing
- [x] Analytics and reporting

### Phase 2: Admin Portal (🔄 In Progress)
- [ ] React.js admin interface
- [ ] Dashboard and analytics
- [ ] Content management system
- [ ] User management

### Phase 3: Mobile App (📋 Planned)
- [ ] React Native mobile app
- [ ] Offline functionality
- [ ] Push notifications
- [ ] Payment integration

### Phase 4: Advanced Features (📋 Future)
- [ ] AI-powered question generation
- [ ] Advanced analytics
- [ ] Multi-language support
- [ ] Social features

---

**Made with ❤️ for job seekers worldwide**
