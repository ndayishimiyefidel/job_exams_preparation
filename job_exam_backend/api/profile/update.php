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

    $name = sanitizeInput($input['name'] ?? '');
    $email = sanitizeInput($input['email'] ?? '');
    $phone = sanitizeInput($input['phone'] ?? '');

    // Validate required fields
    if (empty($name) || empty($email)) {
        sendErrorResponse('Name and email are required', 400);
    }

    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        sendErrorResponse('Invalid email format', 400);
    }

    // Check if email is already taken by another user
    $checkQuery = "SELECT id FROM users WHERE email = ? AND id != ?";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bind_param('si', $email, $current_user['id']);
    $checkStmt->execute();
    $result = $checkStmt->get_result();
    
    if ($result->num_rows > 0) {
        sendErrorResponse('Email is already taken by another user', 400);
    }

    // Update user profile (updated_at will be automatically updated if column exists)
    $query = "UPDATE users SET name = ?, email = ?, phone = ? WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param('sssi', $name, $email, $phone, $current_user['id']);
    
    if ($stmt->execute()) {
        // Log the activity
        logActivity($current_user['id'], 'Profile Updated', "Updated profile information");
        
        // Get updated user data
        $userQuery = "SELECT id, name, email, phone, role, created_at, updated_at FROM users WHERE id = ?";
        $userStmt = $conn->prepare($userQuery);
        $userStmt->bind_param('i', $current_user['id']);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        $userData = $userResult->fetch_assoc();
        
        sendSuccessResponse($userData, 'Profile updated successfully');
    } else {
        sendErrorResponse('Failed to update profile', 500);
    }
    
} catch (Exception $e) {
    sendErrorResponse('Error updating profile: ' . $e->getMessage(), 500);
}
?>
