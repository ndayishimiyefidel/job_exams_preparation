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

// Get form data
$position_id = isset($_POST['position_id']) ? (int)$_POST['position_id'] : 0;
$title = isset($_POST['title']) ? sanitizeInput($_POST['title']) : '';
$type = isset($_POST['type']) ? sanitizeInput($_POST['type']) : 'pdf';
$url = isset($_POST['url']) ? sanitizeInput($_POST['url']) : '';

if ($position_id <= 0 || empty($title)) {
    sendErrorResponse('Position ID and title are required');
}

// Validate position exists
$position_check = "SELECT id, title FROM positions WHERE id = $position_id";
$position_result = mysqli_query($conn, $position_check);

if (mysqli_num_rows($position_result) == 0) {
    sendErrorResponse('Position not found', 404);
}

$position = mysqli_fetch_assoc($position_result);

$file_path = null;

// Handle file upload if provided
if (isset($_FILES['file']) && $_FILES['file']['error'] === UPLOAD_ERR_OK) {
    $file = $_FILES['file'];
    
    // Validate file type based on resource type
    $allowed_types = [];
    switch ($type) {
        case 'pdf':
            $allowed_types = ['application/pdf'];
            break;
        case 'video':
            $allowed_types = ['video/mp4', 'video/avi', 'video/mov'];
            break;
        case 'text':
            $allowed_types = ['text/plain', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
            break;
    }
    
    if (!empty($allowed_types) && !in_array($file['type'], $allowed_types)) {
        sendErrorResponse("Invalid file type for $type resource");
    }
    
    // Upload file
    $upload_dir = '../../uploads/resources/';
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0755, true);
    }
    
    $filename = uploadFile($file, $upload_dir, $allowed_types);
    if (!$filename) {
        sendErrorResponse('Failed to upload file');
    }
    
    $file_path = $filename;
}

// Insert resource
$query = "INSERT INTO resources (position_id, title, file_path, type, url) VALUES ($position_id, '$title', " . 
         ($file_path ? "'$file_path'" : "NULL") . ", '$type', " . ($url ? "'$url'" : "NULL") . ")";

if (mysqli_query($conn, $query)) {
    $resource_id = mysqli_insert_id($conn);
    
    // Log activity
    logActivity($current_user['id'], 'upload_resource', "Uploaded resource: $title for position: " . $position['title']);
    
    sendSuccessResponse([
        'id' => $resource_id,
        'title' => $title,
        'type' => $type,
        'file_path' => $file_path,
        'url' => $url,
        'position_title' => $position['title']
    ], 'Resource uploaded successfully');
} else {
    sendErrorResponse('Failed to upload resource: ' . mysqli_error($conn));
}
?>
