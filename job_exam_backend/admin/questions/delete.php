<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';
setCorsHeaders();
// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow DELETE method
if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    sendErrorResponse('Method not allowed', 405);
}

// Get question ID from URL parameter
$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($id <= 0) {
    sendErrorResponse('Invalid question ID');
}

// Check if question exists
$question_check = "SELECT q.*, e.title as exam_title FROM questions q 
                  LEFT JOIN exams e ON q.exam_id = e.id 
                  WHERE q.id = $id";
$question_result = mysqli_query($conn, $question_check);

if (mysqli_num_rows($question_result) == 0) {
    sendErrorResponse('Question not found', 404);
}

$question = mysqli_fetch_assoc($question_result);

// Start transaction
mysqli_begin_transaction($conn);

try {
    // Delete choices first (foreign key constraint)
    $delete_choices = "DELETE FROM choices WHERE question_id = $id";
    if (!mysqli_query($conn, $delete_choices)) {
        throw new Exception('Failed to delete choices: ' . mysqli_error($conn));
    }
    
    // Delete question
    $delete_question = "DELETE FROM questions WHERE id = $id";
    if (!mysqli_query($conn, $delete_question)) {
        throw new Exception('Failed to delete question: ' . mysqli_error($conn));
    }
    
    // Clear cache for this exam
    $clear_cache = "DELETE FROM question_cache WHERE exam_id = {$question['exam_id']}";
    mysqli_query($conn, $clear_cache);
    
    // Commit transaction
    mysqli_commit($conn);
    
    // Log activity
    logActivity($current_user['id'], 'delete_question', "Deleted question from exam: " . $question['exam_title']);
    
    sendSuccessResponse(null, 'Question deleted successfully');
    
} catch (Exception $e) {
    // Rollback transaction
    mysqli_rollback($conn);
    sendErrorResponse($e->getMessage());
}
?>
