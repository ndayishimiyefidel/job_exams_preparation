<?php
// Set CORS headers for API access
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

try {
    $stats = [];
    
    // Get total positions
    $query = "SELECT COUNT(*) as total FROM positions";
    $result = $conn->query($query);
    $stats['total_positions'] = (int)$result->fetch_assoc()['total'];
    
    // Get total exams
    $query = "SELECT COUNT(*) as total FROM exams";
    $result = $conn->query($query);
    $stats['total_exams'] = (int)$result->fetch_assoc()['total'];
    
    // Get total questions
    $query = "SELECT COUNT(*) as total FROM questions";
    $result = $conn->query($query);
    $stats['total_questions'] = (int)$result->fetch_assoc()['total'];
    
    // Get total users
    $query = "SELECT COUNT(*) as total FROM users";
    $result = $conn->query($query);
    $stats['total_users'] = (int)$result->fetch_assoc()['total'];
    
    // Get recent additions (last 7 days)
    $query = "SELECT COUNT(*) as total FROM positions WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
    $result = $conn->query($query);
    $stats['recent_positions'] = (int)$result->fetch_assoc()['total'];
    
    $query = "SELECT COUNT(*) as total FROM exams WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
    $result = $conn->query($query);
    $stats['recent_exams'] = (int)$result->fetch_assoc()['total'];
    
    $query = "SELECT COUNT(*) as total FROM questions WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
    $result = $conn->query($query);
    $stats['recent_questions'] = (int)$result->fetch_assoc()['total'];
    
    $query = "SELECT COUNT(*) as total FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
    $result = $conn->query($query);
    $stats['recent_users'] = (int)$result->fetch_assoc()['total'];
    
    sendSuccessResponse($stats, 'Dashboard stats retrieved successfully');
    
} catch (Exception $e) {
    sendErrorResponse('Error retrieving dashboard stats: ' . $e->getMessage(), 500);
}
?>
