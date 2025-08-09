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

// Get exam ID
$exam_id = isset($_GET['exam_id']) ? (int)$_GET['exam_id'] : 0;

if ($exam_id <= 0) {
    sendErrorResponse('Invalid exam ID');
}

// Check if exam exists
$exam_check = "SELECT e.*, p.title as position_title FROM exams e 
               LEFT JOIN positions p ON e.position_id = p.id 
               WHERE e.id = $exam_id";
$exam_result = mysqli_query($conn, $exam_check);

if (mysqli_num_rows($exam_result) == 0) {
    sendErrorResponse('Exam not found', 404);
}

$exam = mysqli_fetch_assoc($exam_result);

// Check if user is logged in for paid exams
if ($exam['is_paid']) {
    $auth_header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $token = str_replace('Bearer ', '', $auth_header);
    
    if (empty($token)) {
        sendErrorResponse('Login required for paid exams', 401);
    }
    
    $user = validateApiToken($token);
    if (!$user) {
        sendErrorResponse('Invalid or expired token', 401);
    }
    
    // Check if user has purchased this exam
    $payment_check = "SELECT id FROM payments WHERE user_id = {$user['id']} AND exam_id = $exam_id AND status = 'completed'";
    $payment_result = mysqli_query($conn, $payment_check);
    
    if (mysqli_num_rows($payment_result) == 0) {
        sendErrorResponse('Purchase required for this exam', 403);
    }
}

// Get questions with choices (without correct answer)
$query = "SELECT q.id, q.question_text, c.id as choice_id, c.choice_text
          FROM questions q 
          LEFT JOIN choices c ON q.id = c.question_id 
          WHERE q.exam_id = $exam_id 
          ORDER BY q.id, c.id";

$result = mysqli_query($conn, $query);

if (!$result) {
    sendErrorResponse('Failed to fetch questions: ' . mysqli_error($conn));
}

// Format questions for mobile app
$questions = [];
$current_question = null;

while ($row = mysqli_fetch_assoc($result)) {
    if ($current_question === null || $current_question['id'] !== $row['id']) {
        if ($current_question !== null) {
            $questions[] = $current_question;
        }
        
        $current_question = [
            'id' => (int)$row['id'],
            'question_text' => $row['question_text'],
            'choices' => []
        ];
    }
    
    $current_question['choices'][] = [
        'id' => (int)$row['choice_id'],
        'choice_text' => $row['choice_text']
    ];
}

// Add the last question
if ($current_question !== null) {
    $questions[] = $current_question;
}

// Check cache for faster response
$cache_query = "SELECT cache_json FROM question_cache WHERE exam_id = $exam_id AND last_updated > DATE_SUB(NOW(), INTERVAL 1 HOUR)";
$cache_result = mysqli_query($conn, $cache_query);

if (mysqli_num_rows($cache_result) > 0) {
    $cache_data = mysqli_fetch_assoc($cache_result);
    $cached_questions = json_decode($cache_data['cache_json'], true);
    
    if ($cached_questions) {
        sendSuccessResponse([
            'exam' => [
                'id' => $exam['id'],
                'title' => $exam['title'],
                'position_title' => $exam['position_title'],
                'is_paid' => (bool)$exam['is_paid'],
                'price' => (float)$exam['price']
            ],
            'questions' => $cached_questions,
            'total_questions' => count($cached_questions),
            'cached' => true
        ], 'Questions retrieved successfully (cached)');
    }
}

// Update cache
$cache_json = json_encode($questions);
$cache_update = "INSERT INTO question_cache (exam_id, cache_json) VALUES ($exam_id, '$cache_json') 
                 ON DUPLICATE KEY UPDATE cache_json = '$cache_json', last_updated = NOW()";
mysqli_query($conn, $cache_update);

sendSuccessResponse([
    'exam' => [
        'id' => $exam['id'],
        'title' => $exam['title'],
        'position_title' => $exam['position_title'],
        'is_paid' => (bool)$exam['is_paid'],
        'price' => (float)$exam['price']
    ],
    'questions' => $questions,
    'total_questions' => count($questions),
    'cached' => false
], 'Questions retrieved successfully');
?>
