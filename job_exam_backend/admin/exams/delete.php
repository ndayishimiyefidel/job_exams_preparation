<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is authenticated and is admin
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

try {
    
    // Get exam ID from query parameter
    $exam_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    
    if ($exam_id <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Valid exam ID is required']);
        exit;
    }
    
    // Check if exam exists
    $exam_check = $conn->prepare("SELECT id, title FROM exams WHERE id = ?");
    $exam_check->bind_param('i', $exam_id);
    $exam_check->execute();
    $exam_result = $exam_check->get_result();
    
    if ($exam_result->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Exam not found']);
        exit;
    }
    
    $exam = $exam_result->fetch_assoc();
    
    // Check if exam has questions (optional: prevent deletion if has questions)
    $questions_check = $conn->prepare("SELECT COUNT(*) as count FROM questions WHERE exam_id = ?");
    $questions_check->bind_param('i', $exam_id);
    $questions_check->execute();
    $question_count = $questions_check->get_result()->fetch_assoc()['count'];
    
    if ($question_count > 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false, 
            'message' => "Cannot delete exam '{$exam['title']}' because it has $question_count questions. Please delete the questions first."
        ]);
        exit;
    }
    
    // Delete exam (questions will be deleted automatically due to CASCADE)
    $stmt = $conn->prepare("DELETE FROM exams WHERE id = ?");
    $stmt->bind_param('i', $exam_id);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => "Exam '{$exam['title']}' deleted successfully"
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to delete exam']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

$conn->close();
?>
