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

// Get token from Authorization header for mobile app
$headers = getallheaders();
$auth_header = isset($headers['Authorization']) ? $headers['Authorization'] : '';

if (empty($auth_header) || strpos($auth_header, 'Bearer ') !== 0) {
    sendErrorResponse('Authorization token required', 401);
}

$token = substr($auth_header, 7);

// Validate token and get user
$user = validateApiToken($token);

if (!$user) {
    sendErrorResponse('Invalid or expired token', 401);
}

// Delete API token from database
invalidateApiToken($token);

// Log activity
logActivity($user['id'], 'logout', 'User logged out');

sendSuccessResponse(null, 'Logout successful');
?>
