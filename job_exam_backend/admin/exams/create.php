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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

try {
    
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    if (!isset($input['position_id']) || !isset($input['title'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Position ID and title are required']);
        exit;
    }
    
    $position_id = (int)$input['position_id'];
    $title = trim($input['title']);
    $is_paid = isset($input['is_paid']) ? (bool)$input['is_paid'] : false;
    $price = isset($input['price']) ? (float)$input['price'] : 0.00;
    
    // Validate position exists
    $position_check = $conn->prepare("SELECT id FROM positions WHERE id = ?");
    $position_check->bind_param('i', $position_id);
    $position_check->execute();
    if ($position_check->get_result()->num_rows === 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Position not found']);
        exit;
    }
    
    // Check if exam with same title exists for this position
    $duplicate_check = $conn->prepare("SELECT id FROM exams WHERE position_id = ? AND title = ?");
    $duplicate_check->bind_param('is', $position_id, $title);
    $duplicate_check->execute();
    if ($duplicate_check->get_result()->num_rows > 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Exam with this title already exists for this position']);
        exit;
    }
    
    // Insert new exam
    $stmt = $conn->prepare("INSERT INTO exams (position_id, title, is_paid, price) VALUES (?, ?, ?, ?)");
    $stmt->bind_param('issd', $position_id, $title, $is_paid, $price);
    
    if ($stmt->execute()) {
        $exam_id = $conn->insert_id;
        
        // Get the created exam with position info
        $get_exam = $conn->prepare("
            SELECT e.*, p.title as position_title 
            FROM exams e 
            LEFT JOIN positions p ON e.position_id = p.id 
            WHERE e.id = ?
        ");
        $get_exam->bind_param('i', $exam_id);
        $get_exam->execute();
        $exam = $get_exam->get_result()->fetch_assoc();
        
        echo json_encode([
            'success' => true,
            'message' => 'Exam created successfully',
            'data' => [
                'id' => $exam['id'],
                'position_id' => $exam['position_id'],
                'position_title' => $exam['position_title'],
                'title' => $exam['title'],
                'is_paid' => (bool)$exam['is_paid'],
                'price' => (float)$exam['price'],
                'question_count' => 0,
                'created_at' => $exam['created_at']
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create exam']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

$conn->close();
?>
