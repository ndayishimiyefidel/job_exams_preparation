<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow GET method
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendErrorResponse('Method not allowed', 405);
}

// Get parameters
$position_id = isset($_GET['position_id']) ? (int)$_GET['position_id'] : 0;
$type = isset($_GET['type']) ? sanitizeInput($_GET['type']) : '';
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
$search = isset($_GET['search']) ? sanitizeInput($_GET['search']) : '';

// Build query
$query = "SELECT r.*, p.title as position_title FROM resources r 
          LEFT JOIN positions p ON r.position_id = p.id";

$where_conditions = [];

if ($position_id > 0) {
    $where_conditions[] = "r.position_id = $position_id";
}

if (!empty($type)) {
    $where_conditions[] = "r.type = '$type'";
}

if (!empty($search)) {
    $where_conditions[] = "(r.title LIKE '%$search%' OR p.title LIKE '%$search%')";
}

if (!empty($where_conditions)) {
    $query .= " WHERE " . implode(' AND ', $where_conditions);
}

$query .= " ORDER BY r.created_at DESC";

// Get paginated results
$result = paginateResults($query, $page, $limit);

// Format response
$formatted_data = [];
foreach ($result['data'] as $resource) {
    $formatted_data[] = [
        'id' => (int)$resource['id'],
        'title' => $resource['title'],
        'type' => $resource['type'],
        'file_path' => $resource['file_path'],
        'url' => $resource['url'],
        'position_id' => (int)$resource['position_id'],
        'position_title' => $resource['position_title'],
        'created_at' => $resource['created_at']
    ];
}

$result['data'] = $formatted_data;

sendSuccessResponse($result, 'Resources retrieved successfully');
?>
