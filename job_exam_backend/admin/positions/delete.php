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

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow DELETE method
if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    sendErrorResponse('Method not allowed', 405);
}

// Get position ID from URL parameter
$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($id <= 0) {
    sendErrorResponse('Invalid position ID');
}

// Check if position exists
$check_query = "SELECT title FROM positions WHERE id = $id";
$check_result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($check_result) == 0) {
    sendErrorResponse('Position not found', 404);
}

$position = mysqli_fetch_assoc($check_result);

// Check if position has exams
$exam_check = "SELECT COUNT(*) as exam_count FROM exams WHERE position_id = $id";
$exam_result = mysqli_query($conn, $exam_check);
$exam_count = mysqli_fetch_assoc($exam_result)['exam_count'];

if ($exam_count > 0) {
    sendErrorResponse("Cannot delete position. It has $exam_count exam(s) associated with it.");
}

// Delete position
$query = "DELETE FROM positions WHERE id = $id";

if (mysqli_query($conn, $query)) {
    // Log activity
    logActivity($current_user['id'], 'delete_position', "Deleted position: " . $position['title']);
    
    sendSuccessResponse(null, 'Position deleted successfully');
} else {
    sendErrorResponse('Failed to delete position: ' . mysqli_error($conn));
}
?>
