<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow DELETE method
if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    sendErrorResponse('Method not allowed', 405);
}

// Get resource ID from URL parameter
$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($id <= 0) {
    sendErrorResponse('Invalid resource ID');
}

// Check if resource exists
$resource_check = "SELECT r.*, p.title as position_title FROM resources r 
                  LEFT JOIN positions p ON r.position_id = p.id 
                  WHERE r.id = $id";
$resource_result = mysqli_query($conn, $resource_check);

if (mysqli_num_rows($resource_result) == 0) {
    sendErrorResponse('Resource not found', 404);
}

$resource = mysqli_fetch_assoc($resource_result);

// Delete resource
$query = "DELETE FROM resources WHERE id = $id";

if (mysqli_query($conn, $query)) {
    // Delete physical file if it exists
    if (!empty($resource['file_path'])) {
        $file_path = '../../uploads/resources/' . $resource['file_path'];
        if (file_exists($file_path)) {
            unlink($file_path);
        }
    }
    
    // Log activity
    logActivity($current_user['id'], 'delete_resource', "Deleted resource: {$resource['title']} for position: " . $resource['position_title']);
    
    sendSuccessResponse(null, 'Resource deleted successfully');
} else {
    sendErrorResponse('Failed to delete resource: ' . mysqli_error($conn));
}
?>
