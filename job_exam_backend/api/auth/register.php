<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Allow CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Only allow POST method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendErrorResponse('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$required_fields = ['name', 'email', 'password'];
$missing_fields = validateRequiredFields($input, $required_fields);

if (!empty($missing_fields)) {
    sendErrorResponse('Missing required fields: ' . implode(', ', $missing_fields));
}

// Sanitize input
$name = sanitizeInput($input['name']);
$email = sanitizeInput($input['email']);
$phone = isset($input['phone']) ? sanitizeInput($input['phone']) : null;
$password = $input['password'];

// Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendErrorResponse('Invalid email format');
}

// Validate password strength
if (strlen($password) < 6) {
    sendErrorResponse('Password must be at least 6 characters long');
}

// Check if email already exists
if (emailExists($email)) {
    sendErrorResponse('Email already registered');
}

// Attempt registration
$user_id = createUser($name, $email, $password, 'user', $phone);

if ($user_id) {
    // Auto login after registration
    $user = authenticateUser($email, $password);
    if ($user) {
        $api_token = generateApiToken($user['id']);
        
        sendSuccessResponse([
            'user' => [
                'id' => $user['id'],
                'name' => $user['name'],
                'email' => $user['email'],
                'role' => $user['role'],
                'phone' => $user['phone']
            ],
            'api_token' => $api_token
        ], 'Registration successful');
    } else {
        sendSuccessResponse(null, 'Registration successful. Please login.');
    }
} else {
    sendErrorResponse('Registration failed. Please try again.');
}
?>
