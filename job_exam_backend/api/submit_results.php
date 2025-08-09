<?php
require_once '../includes/auth.php';
require_once '../includes/helpers.php';

// Allow CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Only allow POST method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendErrorResponse('Method not allowed', 405);
}

// Check if user is logged in
if (!isLoggedIn()) {
    sendErrorResponse('Login required', 401);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$required_fields = ['exam_id', 'answers'];
$missing_fields = validateRequiredFields($input, $required_fields);

if (!empty($missing_fields)) {
    sendErrorResponse('Missing required fields: ' . implode(', ', $missing_fields));
}

$user = getCurrentUser();
$exam_id = (int)$input['exam_id'];
$answers = $input['answers'];

if ($exam_id <= 0) {
    sendErrorResponse('Invalid exam ID');
}

if (!is_array($answers)) {
    sendErrorResponse('Answers must be an array');
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

// For paid exams, check if user has purchased
if ($exam['is_paid']) {
    $payment_check = "SELECT id FROM payments WHERE user_id = {$user['id']} AND exam_id = $exam_id AND status = 'completed'";
    $payment_result = mysqli_query($conn, $payment_check);
    
    if (mysqli_num_rows($payment_result) == 0) {
        sendErrorResponse('Purchase required for this exam', 403);
    }
}

// Get correct answers for scoring
$correct_answers_query = "SELECT q.id as question_id, c.id as correct_choice_id
                          FROM questions q 
                          LEFT JOIN choices c ON q.id = c.question_id 
                          WHERE q.exam_id = $exam_id AND c.is_correct = 1";
$correct_answers_result = mysqli_query($conn, $correct_answers_query);

$correct_answers = [];
while ($row = mysqli_fetch_assoc($correct_answers_result)) {
    $correct_answers[$row['question_id']] = $row['correct_choice_id'];
}

// Calculate score
$score_result = calculateExamScore($answers, $correct_answers);
$score = $score_result['score'];
$total_questions = $score_result['total'];
$percentage = $score_result['percentage'];

// Start transaction
mysqli_begin_transaction($conn);

try {
    // Save result
    $result_query = "INSERT INTO results (user_id, exam_id, score, total_questions) 
                     VALUES ({$user['id']}, $exam_id, $score, $total_questions)";
    
    if (!mysqli_query($conn, $result_query)) {
        throw new Exception('Failed to save result: ' . mysqli_error($conn));
    }
    
    $result_id = mysqli_insert_id($conn);
    
    // Log activity
    logActivity($user['id'], 'submit_exam', "Submitted exam: {$exam['title']} - Score: $score/$total_questions ($percentage%)");
    
    // Commit transaction
    mysqli_commit($conn);
    
    // Prepare detailed results for review
    $detailed_results = [];
    foreach ($answers as $question_id => $user_choice_id) {
        $is_correct = isset($correct_answers[$question_id]) && $correct_answers[$question_id] == $user_choice_id;
        
        // Get question and choice details
        $question_query = "SELECT q.question_text, c.choice_text as user_answer, 
                          (SELECT choice_text FROM choices WHERE id = {$correct_answers[$question_id]}) as correct_answer
                          FROM questions q 
                          LEFT JOIN choices c ON c.id = $user_choice_id 
                          WHERE q.id = $question_id";
        $question_result = mysqli_query($conn, $question_query);
        $question_data = mysqli_fetch_assoc($question_result);
        
        $detailed_results[] = [
            'question_id' => (int)$question_id,
            'question_text' => $question_data['question_text'],
            'user_answer' => $question_data['user_answer'],
            'correct_answer' => $question_data['correct_answer'],
            'is_correct' => $is_correct
        ];
    }
    
    sendSuccessResponse([
        'result_id' => $result_id,
        'exam' => [
            'id' => $exam['id'],
            'title' => $exam['title'],
            'position_title' => $exam['position_title']
        ],
        'score' => $score,
        'total_questions' => $total_questions,
        'percentage' => $percentage,
        'detailed_results' => $detailed_results,
        'submitted_at' => date('Y-m-d H:i:s')
    ], 'Exam results submitted successfully');
    
} catch (Exception $e) {
    // Rollback transaction
    mysqli_rollback($conn);
    sendErrorResponse($e->getMessage());
}
?>
