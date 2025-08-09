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
$required_fields = ['exam_id', 'is_paid', 'price'];
$missing_fields = validateRequiredFields($input, $required_fields);

if (!empty($missing_fields)) {
    sendErrorResponse('Missing required fields: ' . implode(', ', $missing_fields));
}

// Sanitize input
$exam_id = (int)$input['exam_id'];
$is_paid = (bool)$input['is_paid'];
$price = (float)$input['price'];

// Check if exam exists
$check_query = "SELECT id, title FROM exams WHERE id = $exam_id";
$check_result = mysqli_query($conn, $check_query);

if (mysqli_num_rows($check_result) == 0) {
    sendErrorResponse('Exam not found', 404);
}

$exam = mysqli_fetch_assoc($check_result);

// Update exam
$query = "UPDATE exams SET is_paid = " . ($is_paid ? 1 : 0) . ", price = $price WHERE id = $exam_id";

if (mysqli_query($conn, $query)) {
    // Log activity
    logActivity($current_user['id'], 'update_exam_pricing', "Updated exam pricing: " . $exam['title'] . " - " . ($is_paid ? "Paid ($price)" : "Free"));
    
    sendSuccessResponse([
        'exam_id' => $exam_id,
        'title' => $exam['title'],
        'is_paid' => $is_paid,
        'price' => $price
    ], 'Exam pricing updated successfully');
} else {
    sendErrorResponse('Failed to update exam: ' . mysqli_error($conn));
}
?>
