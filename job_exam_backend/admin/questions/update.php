<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow PUT method
if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    sendErrorResponse('Method not allowed', 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$required_fields = ['id', 'question_text', 'choices'];
$missing_fields = validateRequiredFields($input, $required_fields);

if (!empty($missing_fields)) {
    sendErrorResponse('Missing required fields: ' . implode(', ', $missing_fields));
}

// Sanitize input
$question_id = (int)$input['id'];
$question_text = sanitizeInput($input['question_text']);
$questionImageUrl = isset($input['questionImageUrl']) ? sanitizeInput($input['questionImageUrl']) : null;
$choices = $input['choices'];

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

// Check if question exists
$question_check = "SELECT q.*, e.title as exam_title FROM questions q 
                  LEFT JOIN exams e ON q.exam_id = e.id 
                  WHERE q.id = $question_id";
$question_result = mysqli_query($conn, $question_check);

if (mysqli_num_rows($question_result) == 0) {
    sendErrorResponse('Question not found', 404);
}

$question = mysqli_fetch_assoc($question_result);

// Start transaction
mysqli_begin_transaction($conn);

try {
    // Update question
    $update_query = "UPDATE questions SET question_text = '$question_text', questionImageUrl = " . 
                   ($questionImageUrl ? "'$questionImageUrl'" : "NULL") . " WHERE id = $question_id";
    
    if (!mysqli_query($conn, $update_query)) {
        throw new Exception('Failed to update question: ' . mysqli_error($conn));
    }
    
    // Delete existing choices
    $delete_choices = "DELETE FROM choices WHERE question_id = $question_id";
    if (!mysqli_query($conn, $delete_choices)) {
        throw new Exception('Failed to delete existing choices: ' . mysqli_error($conn));
    }
    
    // Insert new choices
    foreach ($choices as $choice) {
        $choice_text = sanitizeInput($choice['choice_text']);
        $is_correct = $choice['is_correct'] ? 1 : 0;
        
        $choice_query = "INSERT INTO choices (question_id, choice_text, is_correct) VALUES ($question_id, '$choice_text', $is_correct)";
        
        if (!mysqli_query($conn, $choice_query)) {
            throw new Exception('Failed to insert choice: ' . mysqli_error($conn));
        }
    }
    
    // Clear cache for this exam
    $clear_cache = "DELETE FROM question_cache WHERE exam_id = {$question['exam_id']}";
    mysqli_query($conn, $clear_cache);
    
    // Commit transaction
    mysqli_commit($conn);
    
    // Log activity
    logActivity($current_user['id'], 'update_question', "Updated question for exam: " . $question['exam_title']);
    
    sendSuccessResponse([
        'question_id' => $question_id,
        'exam_title' => $question['exam_title'],
        'question_text' => $question_text,
        'questionImageUrl' => $questionImageUrl,
        'choices_count' => count($choices)
    ], 'Question updated successfully');
    
} catch (Exception $e) {
    // Rollback transaction
    mysqli_rollback($conn);
    sendErrorResponse($e->getMessage());
}
?>
