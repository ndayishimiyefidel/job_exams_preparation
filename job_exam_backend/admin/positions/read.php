<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Get pagination parameters
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
$search = isset($_GET['search']) ? sanitizeInput($_GET['search']) : '';

// Build query
$query = "SELECT p.*, COUNT(e.id) as exam_count FROM positions p LEFT JOIN exams e ON p.id = e.position_id";

if (!empty($search)) {
    $query .= " WHERE p.title LIKE '%$search%' OR p.description LIKE '%$search%'";
}

$query .= " GROUP BY p.id ORDER BY p.created_at DESC";

// Get paginated results
$result = paginateResults($query, $page, $limit);

sendSuccessResponse($result, 'Positions retrieved successfully');
?>
