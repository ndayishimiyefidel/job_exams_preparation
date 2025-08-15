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

try {
    
    // Get query parameters
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
    $search = isset($_GET['search']) ? $_GET['search'] : '';
    $position_id = isset($_GET['position_id']) ? (int)$_GET['position_id'] : 0;
    
    $offset = ($page - 1) * $limit;
    
    // Build WHERE clause
    $where_conditions = [];
    $params = [];
    
    if (!empty($search)) {
        $where_conditions[] = "(e.title LIKE ? OR p.title LIKE ?)";
        $params[] = "%$search%";
        $params[] = "%$search%";
    }
    
    if ($position_id > 0) {
        $where_conditions[] = "e.position_id = ?";
        $params[] = $position_id;
    }
    
    $where_clause = !empty($where_conditions) ? 'WHERE ' . implode(' AND ', $where_conditions) : '';
    
    // Get total count
    $count_sql = "SELECT COUNT(*) as total FROM exams e 
                  LEFT JOIN positions p ON e.position_id = p.id 
                  $where_clause";
    
    $count_stmt = $conn->prepare($count_sql);
    if (!empty($params)) {
        $count_stmt->bind_param(str_repeat('s', count($params)), ...$params);
    }
    $count_stmt->execute();
    $total_records = $count_stmt->get_result()->fetch_assoc()['total'];
    
    // Get exams with position info
    $sql = "SELECT e.*, p.title as position_title, 
            (SELECT COUNT(*) FROM questions q WHERE q.exam_id = e.id) as question_count
            FROM exams e 
            LEFT JOIN positions p ON e.position_id = p.id 
            $where_clause
            ORDER BY e.created_at DESC 
            LIMIT ? OFFSET ?";
    
    $stmt = $conn->prepare($sql);
    
    // Add limit and offset to params
    $params[] = $limit;
    $params[] = $offset;
    
    if (!empty($params)) {
        $stmt->bind_param(str_repeat('s', count($params)), ...$params);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $exams = [];
    while ($row = $result->fetch_assoc()) {
        $exams[] = [
            'id' => $row['id'],
            'position_id' => $row['position_id'],
            'position_title' => $row['position_title'],
            'title' => $row['title'],
            'is_paid' => (bool)$row['is_paid'],
            'price' => (float)$row['price'],
            'question_count' => (int)$row['question_count'],
            'created_at' => $row['created_at']
        ];
    }
    
    $total_pages = ceil($total_records / $limit);
    
    echo json_encode([
        'success' => true,
        'message' => 'Exams retrieved successfully',
        'data' => [
            'data' => $exams,
            'pagination' => [
                'current_page' => $page,
                'per_page' => $limit,
                'total_records' => $total_records,
                'total_pages' => $total_pages,
                'has_next' => $page < $total_pages,
                'has_prev' => $page > 1
            ]
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

$conn->close();
?>
