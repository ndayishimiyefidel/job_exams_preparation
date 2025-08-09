<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow PUT method
if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    sendErrorResponse('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$required_fields = ['id', 'title', 'description'];
$missing_fields = validateRequiredFields($input, $required_fields);

if (!empty($missing_fields)) {
    sendErrorResponse('Missing required fields: ' . implode(', ', $missing_fields));
}

// Sanitize input
$id = (int)$input['id'];
$title = sanitizeInput($input['title']);
$description = sanitizeInput($input['description']);

// Check if position exists
$check_query = "SELECT id FROM positions WHERE id = $id";
$check_result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($check_result) == 0) {
    sendErrorResponse('Position not found', 404);
}

// Update position
$query = "UPDATE positions SET title = '$title', description = '$description' WHERE id = $id";

if (mysqli_query($conn, $query)) {
    // Log activity
    logActivity($current_user['id'], 'update_position', "Updated position ID: $id");
    
    sendSuccessResponse(['id' => $id, 'title' => $title, 'description' => $description], 'Position updated successfully');
} else {
    sendErrorResponse('Failed to update position: ' . mysqli_error($conn));
}
?>
