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
    // Get recent activity logs (last 10)
    $query = "SELECT al.*, u.name as user_name, u.email as user_email 
              FROM activity_logs al 
              LEFT JOIN users u ON al.user_id = u.id 
              ORDER BY al.created_at DESC 
              LIMIT 10";
    
    $result = $conn->query($query);
    
    $activities = [];
    while ($row = $result->fetch_assoc()) {
        $activities[] = [
            'id' => (int)$row['id'],
            'user_id' => $row['user_id'] ? (int)$row['user_id'] : null,
            'user_name' => $row['user_name'] ?: 'System',
            'user_email' => $row['user_email'] ?: '',
            'action' => $row['action'],
            'details' => $row['details'],
            'ip_address' => $row['ip_address'],
            'user_agent' => $row['user_agent'],
            'created_at' => $row['created_at']
        ];
    }
    
    sendSuccessResponse($activities, 'Recent activity retrieved successfully');
    
} catch (Exception $e) {
    sendErrorResponse('Error retrieving recent activity: ' . $e->getMessage(), 500);
}
?>
