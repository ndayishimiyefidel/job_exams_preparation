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

require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in
$current_user = getCurrentUserOrToken();
if (!$current_user) {
    sendErrorResponse('Unauthorized access', 403);
}

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    sendErrorResponse('Method not allowed', 405);
}

try {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        sendErrorResponse('Invalid JSON input', 400);
    }

    $currentPassword = $input['current_password'] ?? '';
    $newPassword = $input['new_password'] ?? '';

    // Validate required fields
    if (empty($currentPassword) || empty($newPassword)) {
        sendErrorResponse('Current password and new password are required', 400);
    }

    // Validate new password length
    if (strlen($newPassword) < 6) {
        sendErrorResponse('New password must be at least 6 characters long', 400);
    }

    // Get current user's password hash
    $userQuery = "SELECT password FROM users WHERE id = ?";
    $userStmt = $conn->prepare($userQuery);
    $userStmt->bind_param('i', $current_user['id']);
    $userStmt->execute();
    $userResult = $userStmt->get_result();
    $userData = $userResult->fetch_assoc();

    if (!$userData) {
        sendErrorResponse('User not found', 404);
    }

    // Verify current password
    if (!password_verify($currentPassword, $userData['password'])) {
        sendErrorResponse('Current password is incorrect', 400);
    }

    // Hash new password
    $newPasswordHash = password_hash($newPassword, PASSWORD_DEFAULT);

    // Update password (updated_at will be automatically updated if column exists)
    $query = "UPDATE users SET password = ? WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param('si', $newPasswordHash, $current_user['id']);
    
    if ($stmt->execute()) {
        // Log the activity
        logActivity($current_user['id'], 'Password Changed', "Password was changed successfully");
        
        sendSuccessResponse(['message' => 'Password changed successfully'], 'Password changed successfully');
    } else {
        sendErrorResponse('Failed to change password', 500);
    }
    
} catch (Exception $e) {
    sendErrorResponse('Error changing password: ' . $e->getMessage(), 500);
}
?>
