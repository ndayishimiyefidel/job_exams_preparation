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
$exam_id = isset($_GET['exam_id']) ? (int)$_GET['exam_id'] : 0;
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;

// Build query
$query = "SELECT q.*, e.title as exam_title, p.title as position_title,
          (SELECT COUNT(*) FROM choices WHERE question_id = q.id) as choice_count
          FROM questions q 
          LEFT JOIN exams e ON q.exam_id = e.id
          LEFT JOIN positions p ON e.position_id = p.id";

if ($exam_id > 0) {
    $query .= " WHERE q.exam_id = $exam_id";
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

sendSuccessResponse($result, 'Questions retrieved successfully');
?>
