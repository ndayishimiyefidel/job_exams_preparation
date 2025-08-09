# Postman Testing Guide for Job Exam System

This guide provides comprehensive testing instructions for the Job Exam System backend using Postman.

## Setup Instructions

### 1. Import Postman Collection
1. Download the `Job_Exam_System.postman_collection.json` file
2. Open Postman
3. Click "Import" and select the collection file
4. The collection will be imported with all endpoints pre-configured

### 2. Environment Setup
Create a new environment in Postman with these variables:

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `base_url` | Your backend base URL | `http://localhost/job_exam_backend` |
| `admin_token` | Admin session token (auto-generated) | (leave empty) |
| `user_token` | User API token (auto-generated) | (leave empty) |
| `exam_id` | Test exam ID | (leave empty) |
| `position_id` | Test position ID | (leave empty) |

## API Testing Scenarios

### 1. System Status Check

**Endpoint**: `GET {{base_url}}/index.php`

**Description**: Check if the API is running and get system information

**Expected Response**:
```json
{
  "success": true,
  "message": "Job Exam System API is running",
  "data": {
    "name": "Job Exam System API",
    "version": "1.0.0",
    "database": {
      "status": "Connected"
    }
  }
}
```

### 2. Admin Authentication

#### 2.1 Admin Login
**Endpoint**: `POST {{base_url}}/admin/auth/login.php`

**Headers**:
```
Content-Type: application/json
```

**Body** (raw JSON):
```json
{
  "email": "admin@jobexam.com",
  "password": "admin123"
}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "name": "Admin User",
      "email": "admin@jobexam.com",
      "role": "admin"
    },
    "session_token": "abc123..."
  }
}
```

**Test Script** (to save token):
```javascript
if (pm.response.code === 200) {
    const response = pm.response.json();
    if (response.success && response.data.session_token) {
        pm.environment.set("admin_token", response.data.session_token);
    }
}
```

### 3. Position Management

#### 3.1 Create Position
**Endpoint**: `POST {{base_url}}/admin/positions/create.php`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer {{admin_token}}
```

**Body** (raw JSON):
```json
{
  "title": "Software Developer",
  "description": "Full-stack development position"
}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Position created successfully",
  "data": {
    "id": 1,
    "title": "Software Developer",
    "description": "Full-stack development position"
  }
}
```

#### 3.2 List Positions
**Endpoint**: `GET {{base_url}}/admin/positions/read.php?page=1&limit=10`

**Headers**:
```
Authorization: Bearer {{admin_token}}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Positions retrieved successfully",
  "data": {
    "data": [
      {
        "id": 1,
        "title": "Software Developer",
        "description": "Full-stack development position",
        "created_at": "2024-01-01 10:00:00"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_records": 1,
      "total_pages": 1
    }
  }
}
```

### 4. Question Management

#### 4.1 Create Individual Question
**Endpoint**: `POST {{base_url}}/admin/questions/create.php`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer {{admin_token}}
```

**Body** (raw JSON):
```json
{
  "exam_id": 1,
  "question_text": "What is the capital of Rwanda?",
  "choices": [
    {
      "choice_text": "Kigali",
      "is_correct": true
    },
    {
      "choice_text": "Musanze",
      "is_correct": false
    },
    {
      "choice_text": "Huye",
      "is_correct": false
    },
    {
      "choice_text": "Rubavu",
      "is_correct": false
    }
  ]
}
```

#### 4.2 Bulk Upload Questions
**Endpoint**: `POST {{base_url}}/admin/questions/upload_bulk.php`

**Headers**:
```
Authorization: Bearer {{admin_token}}
```

**Body** (form-data):
- `exam_id`: `1`
- `file`: Select the `sample_questions.csv` file

**Expected Response**:
```json
{
  "success": true,
  "message": "Bulk upload completed. 5 questions added, 0 failed.",
  "data": {
    "questions_added": 5,
    "questions_failed": 0,
    "exam_title": "Sample Exam"
  }
}
```

### 5. Mobile App API Testing

#### 5.1 User Registration
**Endpoint**: `POST {{base_url}}/api/auth/register.php`

**Headers**:
```
Content-Type: application/json
```

**Body** (raw JSON):
```json
{
  "name": "Test User",
  "email": "test@example.com",
  "password": "password123"
}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": 2,
      "name": "Test User",
      "email": "test@example.com"
    },
    "token": "abc123..."
  }
}
```

**Test Script** (to save token):
```javascript
if (pm.response.code === 200) {
    const response = pm.response.json();
    if (response.success && response.data.token) {
        pm.environment.set("user_token", response.data.token);
    }
}
```

#### 5.2 Get Positions (Mobile)
**Endpoint**: `GET {{base_url}}/api/positions.php?page=1&limit=10`

**Expected Response**:
```json
{
  "success": true,
  "message": "Positions retrieved successfully",
  "data": {
    "data": [
      {
        "id": 1,
        "title": "Software Developer",
        "description": "Full-stack development position"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_records": 1,
      "total_pages": 1
    }
  }
}
```

#### 5.3 Get Exams
**Endpoint**: `GET {{base_url}}/api/exams.php?position_id=1&page=1&limit=10`

**Expected Response**:
```json
{
  "success": true,
  "message": "Exams retrieved successfully",
  "data": {
    "data": [
      {
        "id": 1,
        "title": "Software Development Test",
        "position_id": 1,
        "position_title": "Software Developer",
        "is_paid": false,
        "price": 0.00,
        "question_count": 5
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_records": 1,
      "total_pages": 1
    }
  }
}
```

#### 5.4 Get Questions (Free Exam)
**Endpoint**: `GET {{base_url}}/api/questions.php?exam_id=1`

**Expected Response**:
```json
{
  "success": true,
  "message": "Questions retrieved successfully",
  "data": {
    "exam": {
      "id": 1,
      "title": "Software Development Test",
      "position_title": "Software Developer",
      "is_paid": false,
      "price": 0.00
    },
    "questions": [
      {
        "id": 1,
        "question_text": "What is the capital of Rwanda?",
        "choices": [
          {
            "id": 11,
            "choice_text": "Kigali"
          },
          {
            "id": 12,
            "choice_text": "Musanze"
          },
          {
            "id": 13,
            "choice_text": "Huye"
          },
          {
            "id": 14,
            "choice_text": "Rubavu"
          }
        ]
      }
    ],
    "total_questions": 1,
    "cached": false
  }
}
```

#### 5.5 Submit Exam Results
**Endpoint**: `POST {{base_url}}/api/submit_results.php`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer {{user_token}}
```

**Body** (raw JSON):
```json
{
  "exam_id": 1,
  "answers": {
    "1": 11,
    "2": 15,
    "3": 19
  }
}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Results submitted successfully",
  "data": {
    "score": 2,
    "total_questions": 3,
    "percentage": 66.67,
    "incorrect_answers": [3],
    "result_id": 1
  }
}
```

### 6. Error Testing

#### 6.1 Invalid Authentication
**Endpoint**: `GET {{base_url}}/api/questions.php?exam_id=1`

**Headers**:
```
Authorization: Bearer invalid_token
```

**Expected Response**:
```json
{
  "success": false,
  "message": "Invalid or expired token"
}
```

#### 6.2 Missing Required Fields
**Endpoint**: `POST {{base_url}}/api/auth/login.php`

**Body** (raw JSON):
```json
{
  "email": "test@example.com"
}
```

**Expected Response**:
```json
{
  "success": false,
  "message": "Missing required fields",
  "errors": ["password"]
}
```

## Testing Checklist

### ✅ Basic Functionality
- [ ] System status check
- [ ] Admin login/logout
- [ ] User registration/login
- [ ] Position CRUD operations
- [ ] Question creation and bulk upload
- [ ] Exam listing and access
- [ ] Question retrieval (free exams)
- [ ] Result submission and scoring

### ✅ Security Testing
- [ ] Invalid authentication tokens
- [ ] Missing required fields
- [ ] Unauthorized access attempts
- [ ] SQL injection attempts
- [ ] XSS payload testing

### ✅ Performance Testing
- [ ] Large dataset pagination
- [ ] Question caching functionality
- [ ] File upload limits
- [ ] Concurrent user access

### ✅ Edge Cases
- [ ] Empty data sets
- [ ] Invalid file formats
- [ ] Network timeouts
- [ ] Database connection issues

## Troubleshooting

### Common Issues

1. **CORS Errors**
   - Ensure the backend is running on the correct domain
   - Check that CORS headers are properly set

2. **Authentication Failures**
   - Verify token format (Bearer token)
   - Check token expiration
   - Ensure proper user roles

3. **File Upload Issues**
   - Check file size limits
   - Verify file format restrictions
   - Ensure proper directory permissions

4. **Database Errors**
   - Verify database connection
   - Check table structure
   - Ensure proper foreign key relationships

## Sample Data

Use the provided sample files for testing:
- `sample_questions.csv` - For bulk upload testing
- `sample_question_format.json` - For format reference

## Performance Benchmarks

Expected response times:
- Simple GET requests: < 200ms
- Complex queries with pagination: < 500ms
- File uploads: < 2s (depending on file size)
- Bulk operations: < 5s (depending on data size)
