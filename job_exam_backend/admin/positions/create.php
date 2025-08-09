<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow POST method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendErrorResponse('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$required_fields = ['title', 'description'];
$missing_fields = validateRequiredFields($input, $required_fields);

if (!empty($missing_fields)) {
    sendErrorResponse('Missing required fields: ' . implode(', ', $missing_fields));
}

// Sanitize input
$title = sanitizeInput($input['title']);
$description = sanitizeInput($input['description']);

// Insert into database
$query = "INSERT INTO positions (title, description) VALUES ('$title', '$description')";

if (mysqli_query($conn, $query)) {
    $position_id = mysqli_insert_id($conn);
    
    // Log activity
    logActivity($current_user['id'], 'create_position', "Created position: $title");
    
    sendSuccessResponse(['id' => $position_id, 'title' => $title, 'description' => $description], 'Position created successfully');
} else {
    sendErrorResponse('Failed to create position: ' . mysqli_error($conn));
}
?>
