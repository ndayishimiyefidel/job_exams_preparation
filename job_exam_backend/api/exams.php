<?php
require_once '../includes/auth.php';
require_once '../includes/helpers.php';

// Allow CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Only allow GET method
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendErrorResponse('Method not allowed', 405);
}

// Get parameters
$position_id = isset($_GET['position_id']) ? (int)$_GET['position_id'] : 0;
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
$show_free_only = isset($_GET['free_only']) ? (bool)$_GET['free_only'] : false;

// Build query
$query = "SELECT e.*, p.title as position_title, COUNT(q.id) as question_count
          FROM exams e 
          LEFT JOIN positions p ON e.position_id = p.id
          LEFT JOIN questions q ON e.id = q.exam_id";

$where_conditions = [];

if ($position_id > 0) {
    $where_conditions[] = "e.position_id = $position_id";
}

if ($show_free_only) {
    $where_conditions[] = "e.is_paid = 0";
}

if (!empty($where_conditions)) {
    $query .= " WHERE " . implode(' AND ', $where_conditions);
}

$query .= " GROUP BY e.id ORDER BY e.created_at DESC";

// Get paginated results
$result = paginateResults($query, $page, $limit);

// Format response for mobile app
$formatted_data = [];
foreach ($result['data'] as $exam) {
    $formatted_data[] = [
        'id' => $exam['id'],
        'title' => $exam['title'],
        'position_id' => (int)$exam['position_id'],
        'position_title' => $exam['position_title'],
        'is_paid' => (bool)$exam['is_paid'],
        'price' => (float)$exam['price'],
        'question_count' => (int)$exam['question_count'],
        'created_at' => $exam['created_at']
    ];
}

$result['data'] = $formatted_data;

sendSuccessResponse($result, 'Exams retrieved successfully');
?>
