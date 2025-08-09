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

// Auth: require Bearer token (no session)
$headers = function_exists('getallheaders') ? getallheaders() : [];
if (!$headers) {
    foreach ($_SERVER as $name => $value) {
        if (substr($name, 0, 5) === 'HTTP_') {
            $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
        }
    }
}
$authHeader = $headers['Authorization'] ?? '';
if (empty($authHeader) || stripos($authHeader, 'Bearer ') !== 0) {
    sendErrorResponse('Authorization token required', 401);
}
$token = substr($authHeader, 7);
$user = validateApiToken($token);
if (!$user) {
    sendErrorResponse('Invalid or expired token', 401);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$required_fields = ['exam_id', 'payment_method', 'amount'];
$missing_fields = validateRequiredFields($input, $required_fields);

if (!empty($missing_fields)) {
    sendErrorResponse('Missing required fields: ' . implode(', ', $missing_fields));
}

$exam_id = (int)$input['exam_id'];
$payment_method = sanitizeInput($input['payment_method']);
$amount = (float)$input['amount'];

// Check if exam exists and is paid
$exam_check = "SELECT e.*, p.title as position_title FROM exams e 
               LEFT JOIN positions p ON e.position_id = p.id 
               WHERE e.id = $exam_id AND e.is_paid = 1";
$exam_result = mysqli_query($conn, $exam_check);

if (mysqli_num_rows($exam_result) == 0) {
    sendErrorResponse('Paid exam not found', 404);
}

$exam = mysqli_fetch_assoc($exam_result);

// Validate amount
if ($amount != $exam['price']) {
    sendErrorResponse('Invalid payment amount');
}

// Check if user already purchased this exam
$existing_payment = "SELECT id FROM payments WHERE user_id = {$user['id']} AND exam_id = $exam_id AND status = 'completed'";
$existing_result = mysqli_query($conn, $existing_payment);

if (mysqli_num_rows($existing_result) > 0) {
    sendErrorResponse('You have already purchased this exam');
}

// Start transaction
mysqli_begin_transaction($conn);

try {
    // Create payment record
    $payment_query = "INSERT INTO payments (user_id, exam_id, amount, status) VALUES ({$user['id']}, $exam_id, $amount, 'pending')";
    
    if (!mysqli_query($conn, $payment_query)) {
        throw new Exception('Failed to create payment record: ' . mysqli_error($conn));
    }
    
    $payment_id = mysqli_insert_id($conn);
    
    // Simulate payment processing (replace with actual payment gateway integration)
    $payment_successful = true; // This would be determined by payment gateway response
    
    if ($payment_successful) {
        // Update payment status to completed
        $update_payment = "UPDATE payments SET status = 'completed' WHERE id = $payment_id";
        
        if (!mysqli_query($conn, $update_payment)) {
            throw new Exception('Failed to update payment status: ' . mysqli_error($conn));
        }
        
        // Log activity
        logActivity($user['id'], 'purchase_exam', "Purchased exam: {$exam['title']} for $" . number_format($amount, 2));
        
        // Commit transaction
        mysqli_commit($conn);
        
        sendSuccessResponse([
            'payment_id' => $payment_id,
            'exam' => [
                'id' => $exam['id'],
                'title' => $exam['title'],
                'position_title' => $exam['position_title']
            ],
            'amount' => $amount,
            'status' => 'completed',
            'purchase_date' => date('Y-m-d H:i:s')
        ], 'Payment completed successfully');
        
    } else {
        // Update payment status to failed
        $update_payment = "UPDATE payments SET status = 'failed' WHERE id = $payment_id";
        mysqli_query($conn, $update_payment);
        
        throw new Exception('Payment processing failed');
    }
    
} catch (Exception $e) {
    // Rollback transaction
    mysqli_rollback($conn);
    sendErrorResponse($e->getMessage());
}
?>
