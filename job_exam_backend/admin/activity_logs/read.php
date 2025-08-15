<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

function setCorsHeaders() {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
}

setCorsHeaders();

try {
    // Get authentication token
    $headers = getallheaders();
    $token = null;
    
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        if (strpos($authHeader, 'Bearer ') === 0) {
            $token = substr($authHeader, 7);
        }
    }
    
    // Verify authentication
    if (!$token) {
        http_response_code(401);
        echo json_encode(['error' => 'No token provided']);
        exit();
    }
    
    $user = verifyToken($token);
    if (!$user || $user['role'] !== 'admin') {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized access']);
        exit();
    }
    
    // Get query parameters
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
    $search = isset($_GET['search']) ? $_GET['search'] : '';
    $action = isset($_GET['action']) ? $_GET['action'] : '';
    $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    
    // Validate parameters
    $page = max(1, $page);
    $limit = max(1, min(100, $limit));
    $offset = ($page - 1) * $limit;
    
    // Build WHERE clause
    $whereConditions = [];
    $params = [];
    
    if (!empty($search)) {
        $whereConditions[] = "(al.action LIKE ? OR al.details LIKE ? OR u.name LIKE ?)";
        $searchParam = "%$search%";
        $params[] = $searchParam;
        $params[] = $searchParam;
        $params[] = $searchParam;
    }
    
    if (!empty($action)) {
        $whereConditions[] = "al.action = ?";
        $params[] = $action;
    }
    
    if ($user_id > 0) {
        $whereConditions[] = "al.user_id = ?";
        $params[] = $user_id;
    }
    
    $whereClause = !empty($whereConditions) ? 'WHERE ' . implode(' AND ', $whereConditions) : '';
    
    // Get total count
    $countQuery = "SELECT COUNT(*) as total FROM activity_logs al 
                   LEFT JOIN users u ON al.user_id = u.id 
                   $whereClause";
    
    $stmt = $conn->prepare($countQuery);
    if (!empty($params)) {
        $stmt->bind_param(str_repeat('s', count($params)), ...$params);
    }
    $stmt->execute();
    $countResult = $stmt->get_result();
    $totalRecords = $countResult->fetch_assoc()['total'];
    
    // Get activity logs
    $query = "SELECT al.*, u.name as user_name, u.email as user_email 
              FROM activity_logs al 
              LEFT JOIN users u ON al.user_id = u.id 
              $whereClause 
              ORDER BY al.created_at DESC 
              LIMIT ? OFFSET ?";
    
    $stmt = $conn->prepare($query);
    
    // Add limit and offset to params
    $params[] = $limit;
    $params[] = $offset;
    
    if (!empty($params)) {
        $stmt->bind_param(str_repeat('s', count($params)), ...$params);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $activityLogs = [];
    while ($row = $result->fetch_assoc()) {
        $activityLogs[] = [
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
    
    $totalPages = ceil($totalRecords / $limit);
    
    echo json_encode([
        'success' => true,
        'activity_logs' => $activityLogs,
        'pagination' => [
            'current_page' => $page,
            'total_pages' => $totalPages,
            'total_records' => $totalRecords,
            'limit' => $limit,
            'offset' => $offset
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal server error',
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>
