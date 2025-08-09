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

// Get pagination parameters
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
$search = isset($_GET['search']) ? sanitizeInput($_GET['search']) : '';

// Build query to get positions with exam counts
$query = "SELECT p.*, COUNT(e.id) as exam_count, 
          COUNT(CASE WHEN e.is_paid = 0 THEN 1 END) as free_exam_count,
          COUNT(CASE WHEN e.is_paid = 1 THEN 1 END) as paid_exam_count
          FROM positions p 
          LEFT JOIN exams e ON p.id = e.position_id";

if (!empty($search)) {
    $query .= " WHERE p.title LIKE '%$search%' OR p.description LIKE '%$search%'";
}

$query .= " GROUP BY p.id ORDER BY p.created_at DESC";

// Get paginated results
$result = paginateResults($query, $page, $limit);

// Format response for mobile app
$formatted_data = [];
foreach ($result['data'] as $position) {
    $formatted_data[] = [
        'id' => $position['id'],
        'title' => $position['title'],
        'description' => $position['description'],
        'exam_count' => (int)$position['exam_count'],
        'free_exam_count' => (int)$position['free_exam_count'],
        'paid_exam_count' => (int)$position['paid_exam_count'],
        'created_at' => $position['created_at']
    ];
}

$result['data'] = $formatted_data;

sendSuccessResponse($result, 'Positions retrieved successfully');
?>
