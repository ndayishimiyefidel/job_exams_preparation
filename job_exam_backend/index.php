<?php
require_once 'config/db_connect.php';
require_once 'includes/helpers.php';

// Set headers for API responses
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// API Information
$api_info = [
    'name' => 'Job Exam System API',
    'version' => '1.0.0',
    'description' => 'Backend API for Job Exam Preparation System',
    'endpoints' => [
        'admin' => [
            'positions' => [
                'POST /admin/positions/create.php' => 'Create new position',
                'GET /admin/positions/read.php' => 'List positions with pagination',
                'PUT /admin/positions/update.php' => 'Update position',
                'DELETE /admin/positions/delete.php' => 'Delete position'
            ],
            'questions' => [
                'POST /admin/questions/create.php' => 'Create individual question',
                'POST /admin/questions/upload_bulk.php' => 'Upload questions via CSV/Excel',
                'GET /admin/questions/read.php' => 'List questions',
                'PUT /admin/questions/update.php' => 'Update question',
                'DELETE /admin/questions/delete.php' => 'Delete question'
            ],
            'exams' => [
                'PUT /admin/exams/mark_free_paid.php' => 'Mark exam as free or paid',
                'GET /admin/exams/list.php' => 'List exams'
            ],
            'analytics' => [
                'GET /admin/analytics/usage.php' => 'Get usage analytics'
            ]
        ],
        'api' => [
            'auth' => [
                'POST /api/auth/login.php' => 'User login',
                'POST /api/auth/register.php' => 'User registration',
                'POST /api/auth/logout.php' => 'User logout'
            ],
            'mobile' => [
                'GET /api/positions.php' => 'Get positions for mobile app',
                'GET /api/exams.php' => 'Get exams for mobile app',
                'GET /api/questions.php' => 'Get exam questions (without answers)',
                'POST /api/submit_results.php' => 'Submit exam results',
                'GET /api/resources.php' => 'Get study resources',
                'POST /api/payments.php' => 'Process payments'
            ]
        ]
    ],
    'database' => [
        'status' => 'Connected',
        'tables' => [
            'users' => 'User accounts and authentication',
            'positions' => 'Job positions/categories',
            'exams' => 'Exams linked to positions',
            'questions' => 'Exam questions',
            'choices' => 'Multiple choice options',
            'resources' => 'Study materials and guides',
            'payments' => 'Payment transactions',
            'results' => 'Exam results and scores',
            'question_cache' => 'Cached questions for performance',
            'api_tokens' => 'Mobile app authentication tokens',
            'activity_logs' => 'Admin activity tracking'
        ]
    ],
    'features' => [
        'Free and paid exams',
        'Bulk question upload via CSV/Excel',
        'Mobile app support with API tokens',
        'Question caching for performance',
        'Payment processing',
        'Analytics and reporting',
        'Activity logging',
        'CORS support for cross-origin requests'
    ],
    'setup' => [
        'database' => 'Import job_exam_system.sql to create database and tables',
        'admin_login' => 'Email: admin@jobexam.com, Password: admin123',
        'uploads' => 'Create uploads/ and cache/ directories with write permissions',
        'config' => 'Update config/db_connect.php with your database credentials'
    ]
];

// Check database connection
try {
    $test_query = "SELECT 1";
    $test_result = mysqli_query($conn, $test_query);
    
    if (!$test_result) {
        $api_info['database']['status'] = 'Error: ' . mysqli_error($conn);
    }
} catch (Exception $e) {
    $api_info['database']['status'] = 'Error: ' . $e->getMessage();
}

// Return API information
sendSuccessResponse($api_info, 'Job Exam System API is running');
?>
