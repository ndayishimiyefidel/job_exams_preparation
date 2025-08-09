<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow POST method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendErrorResponse('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$required_fields = ['exam_id', 'question_text', 'choices'];
$missing_fields = validateRequiredFields($input, $required_fields);

if (!empty($missing_fields)) {
    sendErrorResponse('Missing required fields: ' . implode(', ', $missing_fields));
}

// Sanitize input
$exam_id = (int)$input['exam_id'];
$question_text = sanitizeInput($input['question_text']);
$questionImageUrl = isset($input['questionImageUrl']) ? sanitizeInput($input['questionImageUrl']) : null;
$choices = $input['choices'];

// Validate exam exists
$exam_check = "SELECT id, title FROM exams WHERE id = $exam_id";
$exam_result = mysqli_query($conn, $exam_check);

if (mysqli_num_rows($exam_result) == 0) {
    sendErrorResponse('Exam not found', 404);
}

$exam = mysqli_fetch_assoc($exam_result);

// Validate choices
if (!is_array($choices) || count($choices) < 2 || count($choices) > 5) {
    sendErrorResponse('Question must have 2-5 choices');
}

// Validate choices structure and ensure exactly one correct answer
$correct_count = 0;
foreach ($choices as $choice) {
    if (!isset($choice['choice_text']) || !isset($choice['is_correct'])) {
        sendErrorResponse('Each choice must have choice_text and is_correct properties');
    }
    if ($choice['is_correct']) {
        $correct_count++;
    }
}

if ($correct_count !== 1) {
    sendErrorResponse('Question must have exactly one correct answer');
}

// Start transaction
mysqli_begin_transaction($conn);

try {
    // Insert question
    $question_query = "INSERT INTO questions (exam_id, question_text, questionImageUrl) VALUES ($exam_id, '$question_text', " . 
                     ($questionImageUrl ? "'$questionImageUrl'" : "NULL") . ")";
    
    if (!mysqli_query($conn, $question_query)) {
        throw new Exception('Failed to insert question: ' . mysqli_error($conn));
    }
    
    $question_id = mysqli_insert_id($conn);
    
    // Insert choices
    foreach ($choices as $choice) {
        $choice_text = sanitizeInput($choice['choice_text']);
        $is_correct = $choice['is_correct'] ? 1 : 0;
        
        $choice_query = "INSERT INTO choices (question_id, choice_text, is_correct) VALUES ($question_id, '$choice_text', $is_correct)";
        
        if (!mysqli_query($conn, $choice_query)) {
            throw new Exception('Failed to insert choice: ' . mysqli_error($conn));
        }
    }
    
    // Commit transaction
    mysqli_commit($conn);
    
    // Log activity
    logActivity($current_user['id'], 'create_question', "Created question for exam: " . $exam['title']);
    
    sendSuccessResponse([
        'question_id' => $question_id,
        'exam_title' => $exam['title'],
        'question_text' => $question_text,
        'questionImageUrl' => $questionImageUrl,
        'choices_count' => count($choices)
    ], 'Question created successfully');
    
} catch (Exception $e) {
    // Rollback transaction
    mysqli_rollback($conn);
    sendErrorResponse($e->getMessage());
}
?>
