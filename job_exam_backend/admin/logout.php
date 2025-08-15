<?php
// Set CORS headers for API access
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../includes/auth.php';
require_once '../includes/helpers.php';

// Check if user is logged in
$current_user = getCurrentUser();
if ($current_user) {
    // Log activity before ending session
    logActivity($current_user['id'], 'admin_logout', 'Admin logged out');
    
    // End user session
    endUserSession();
    
    sendSuccessResponse(null, 'Logout successful');
} else {
    sendErrorResponse('No active session', 401);
}
?>
