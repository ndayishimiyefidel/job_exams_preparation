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
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
$search = isset($_GET['search']) ? sanitizeInput($_GET['search']) : '';

// Build query
$query = "SELECT e.*, p.title as position_title, 
          COUNT(q.id) as question_count,
          COUNT(r.id) as attempt_count,
          AVG(r.score) as avg_score
          FROM exams e 
          LEFT JOIN positions p ON e.position_id = p.id
          LEFT JOIN questions q ON e.id = q.exam_id
          LEFT JOIN results r ON e.id = r.exam_id";

$where_conditions = [];

if ($position_id > 0) {
    $where_conditions[] = "e.position_id = $position_id";
}

if (!empty($search)) {
    $where_conditions[] = "(e.title LIKE '%$search%' OR p.title LIKE '%$search%')";
}

if (!empty($where_conditions)) {
    $query .= " WHERE " . implode(' AND ', $where_conditions);
}

$query .= " GROUP BY e.id ORDER BY e.created_at DESC";

// Get paginated results
$result = paginateResults($query, $page, $limit);

// Format response
$formatted_data = [];
foreach ($result['data'] as $exam) {
    $formatted_data[] = [
        'id' => (int)$exam['id'],
        'title' => $exam['title'],
        'position_id' => (int)$exam['position_id'],
        'position_title' => $exam['position_title'],
        'is_paid' => (bool)$exam['is_paid'],
        'price' => (float)$exam['price'],
        'question_count' => (int)$exam['question_count'],
        'attempt_count' => (int)$exam['attempt_count'],
        'avg_score' => round((float)$exam['avg_score'], 2),
        'created_at' => $exam['created_at']
    ];
}

$result['data'] = $formatted_data;

sendSuccessResponse($result, 'Exams retrieved successfully');
?>
