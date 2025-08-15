<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';
setCorsHeaders();

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
$exam_id = isset($_GET['exam_id']) ? (int)$_GET['exam_id'] : 0;
$search = isset($_GET['search']) ? sanitizeInput($_GET['search']) : '';
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;

// Build query
$query = "SELECT q.id, q.exam_id, q.question_text, q.question_marks, q.questionImageUrl, q.created_at,
          e.title as exam_title, p.title as position_title,
          (SELECT COUNT(*) FROM choices WHERE question_id = q.id) as choice_count
          FROM questions q 
          LEFT JOIN exams e ON q.exam_id = e.id
          LEFT JOIN positions p ON e.position_id = p.id";

$where_conditions = [];

if ($exam_id > 0) {
    $where_conditions[] = "q.exam_id = $exam_id";
}

if (!empty($search)) {
    $search_term = mysqli_real_escape_string($conn, $search);
    $where_conditions[] = "(q.question_text LIKE '%$search_term%' OR e.title LIKE '%$search_term%' OR p.title LIKE '%$search_term%')";
}

if (!empty($where_conditions)) {
    $query .= " WHERE " . implode(' AND ', $where_conditions);
}

$query .= " ORDER BY q.created_at DESC";

// Get paginated results
$result = paginateResults($query, $page, $limit);

// Get choices for each question
foreach ($result['data'] as &$question) {
    $choices_query = "SELECT id, choice_text, is_correct FROM choices WHERE question_id = {$question['id']} ORDER BY id";
    $choices_result = mysqli_query($conn, $choices_query);
    
    $question['choices'] = [];
    while ($choice = mysqli_fetch_assoc($choices_result)) {
        $question['choices'][] = [
            'id' => (int)$choice['id'],
            'choice_text' => $choice['choice_text'],
            'is_correct' => (bool)$choice['is_correct']
        ];
    }
}

// Restructure response to match frontend expectations
$response = [
    'data' => $result['data'],
    'total_records' => $result['pagination']['total_records'],
    'total_pages' => $result['pagination']['total_pages'],
    'current_page' => $result['pagination']['current_page'],
    'limit' => $result['pagination']['per_page']
];

sendSuccessResponse($response, 'Questions retrieved successfully');
?>
