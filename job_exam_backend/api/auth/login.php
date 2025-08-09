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
$required_fields = ['email', 'password'];
$missing_fields = validateRequiredFields($input, $required_fields);

if (!empty($missing_fields)) {
    sendErrorResponse('Missing required fields: ' . implode(', ', $missing_fields));
}

// Sanitize input
$email = sanitizeInput($input['email']);
$password = $input['password'];

// Attempt login
$user = authenticateUser($email, $password);

if ($user) {
    // Generate API token for mobile app
    $api_token = generateApiToken($user['id']);
    
    sendSuccessResponse([
        'user' => [
            'id' => $user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'role' => $user['role']
        ],
        'api_token' => $api_token
    ], 'Login successful');
} else {
    sendErrorResponse('Invalid email or password', 401);
}
?>
