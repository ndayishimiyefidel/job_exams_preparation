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

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    sendErrorResponse('Method not allowed', 405);
}

try {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        sendErrorResponse('Invalid JSON input', 400);
    }

    $password = $input['password'] ?? '';

    // Validate required fields
    if (empty($password)) {
        sendErrorResponse('Password is required to delete account', 400);
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

    // Verify password
    if (!password_verify($password, $userData['password'])) {
        sendErrorResponse('Password is incorrect', 400);
    }

    // Start transaction
    $conn->begin_transaction();

    try {
        // Delete user's activity logs
        $deleteLogsQuery = "DELETE FROM activity_logs WHERE user_id = ?";
        $deleteLogsStmt = $conn->prepare($deleteLogsQuery);
        $deleteLogsStmt->bind_param('i', $current_user['id']);
        $deleteLogsStmt->execute();

        // Delete user's API tokens
        $deleteTokensQuery = "DELETE FROM api_tokens WHERE user_id = ?";
        $deleteTokensStmt = $conn->prepare($deleteTokensQuery);
        $deleteTokensStmt->bind_param('i', $current_user['id']);
        $deleteTokensStmt->execute();

        // Delete user
        $deleteUserQuery = "DELETE FROM users WHERE id = ?";
        $deleteUserStmt = $conn->prepare($deleteUserQuery);
        $deleteUserStmt->bind_param('i', $current_user['id']);
        
        if ($deleteUserStmt->execute()) {
            // Commit transaction
            $conn->commit();
            
            sendSuccessResponse(['message' => 'Account deleted successfully'], 'Account deleted successfully');
        } else {
            throw new Exception('Failed to delete user');
        }
        
    } catch (Exception $e) {
        // Rollback transaction
        $conn->rollback();
        throw $e;
    }
    
} catch (Exception $e) {
    sendErrorResponse('Error deleting account: ' . $e->getMessage(), 500);
}
?>
