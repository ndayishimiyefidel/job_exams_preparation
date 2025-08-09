<?php
require_once __DIR__ . '/../config/db_connect.php';

/**
 * Send success JSON response
 * @param mixed $data Response data
 * @param string $message Success message
 * @param int $status_code HTTP status code
 * @return void
 */
function sendSuccessResponse($data, $message = 'Success', $status_code = 200) {
    http_response_code($status_code);
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}

/**
 * Send error JSON response
 * @param string $message Error message
 * @param int $status_code HTTP status code
 * @param mixed $errors Additional error details
 * @return void
 */
function sendErrorResponse($message, $status_code = 400, $errors = null) {
    http_response_code($status_code);
    $response = [
        'success' => false,
        'message' => $message
    ];
    
    if ($errors !== null) {
        $response['errors'] = $errors;
    }
    
    echo json_encode($response);
    exit;
}

/**
 * Sanitize input data
 * @param mixed $data Input data
 * @return mixed Sanitized data
 */
function sanitizeInput($data) {
    if (is_array($data)) {
        return array_map('sanitizeInput', $data);
    }
    
    return htmlspecialchars(trim($data), ENT_QUOTES, 'UTF-8');
}

/**
 * Validate required fields
 * @param array $data Input data
 * @param array $required_fields Array of required field names
 * @return array Array of missing fields
 */
function validateRequiredFields($data, $required_fields) {
    $missing_fields = [];
    
    foreach ($required_fields as $field) {
        if (!isset($data[$field])) {
            $missing_fields[] = $field;
        } else {
            $value = $data[$field];
            
            // Handle different data types
            if (is_array($value)) {
                // For arrays, check if it's empty
                if (empty($value)) {
                    $missing_fields[] = $field;
                }
            } else {
                // For strings, trim and check if empty
                if (empty(trim($value))) {
                    $missing_fields[] = $field;
                }
            }
        }
    }
    
    return $missing_fields;
}

/**
 * Paginate database results
 * @param string $query Base SQL query
 * @param int $page Current page number
 * @param int $limit Items per page
 * @return array Paginated results with metadata
 */
function paginateResults($query, $page = 1, $limit = 10) {
    global $conn;
    
    $page = max(1, (int)$page);
    $limit = max(1, min(100, (int)$limit)); // Limit between 1 and 100
    $offset = ($page - 1) * $limit;
    
    // Get total count
    $count_query = "SELECT COUNT(*) as total FROM ($query) as count_table";
    $count_result = mysqli_query($conn, $count_query);
    $total_records = mysqli_fetch_assoc($count_result)['total'];
    
    // Get paginated data
    $paginated_query = $query . " LIMIT $limit OFFSET $offset";
    $result = mysqli_query($conn, $paginated_query);
    
    $data = [];
    if ($result) {
        while ($row = mysqli_fetch_assoc($result)) {
            $data[] = $row;
        }
    }
    
    $total_pages = ceil($total_records / $limit);
    
    return [
        'data' => $data,
        'pagination' => [
            'current_page' => $page,
            'per_page' => $limit,
            'total_records' => (int)$total_records,
            'total_pages' => $total_pages,
            'has_next' => $page < $total_pages,
            'has_prev' => $page > 1
        ]
    ];
}

/**
 * Upload file with validation
 * @param array $file $_FILES array element
 * @param string $upload_dir Upload directory path
 * @param array $allowed_types Allowed file types
 * @param int $max_size Maximum file size in bytes
 * @return string|false File path on success, false on failure
 */
function uploadFile($file, $upload_dir, $allowed_types = [], $max_size = 5242880) {
    // Check for upload errors
    if ($file['error'] !== UPLOAD_ERR_OK) {
        return false;
    }
    
    // Check file size
    if ($file['size'] > $max_size) {
        return false;
    }
    
    // Check file type
    $file_extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!empty($allowed_types) && !in_array($file_extension, $allowed_types)) {
        return false;
    }
    
    // Create upload directory if it doesn't exist
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0755, true);
    }
    
    // Generate unique filename
    $filename = uniqid() . '_' . time() . '.' . $file_extension;
    $filepath = $upload_dir . '/' . $filename;
    
    // Move uploaded file
    if (move_uploaded_file($file['tmp_name'], $filepath)) {
        return $filepath;
    }
    
    return false;
}

/**
 * Log admin activity
 * @param int $user_id Admin user ID
 * @param string $action Action performed
 * @param string $details Additional details
 * @param string $ip_address IP address
 * @return bool Success status
 */
function logActivity($user_id, $action, $details = '', $ip_address = '') {
    global $conn;
    
    $user_id = (int)$user_id;
    $action = escapeString($conn, $action);
    $details = escapeString($conn, $details);
    $ip_address = escapeString($conn, $ip_address ?: $_SERVER['REMOTE_ADDR'] ?? '');
    
    // If user_id is 0 or invalid, set it to NULL for the database
    $user_id_value = ($user_id > 0) ? $user_id : 'NULL';
    
    $query = "INSERT INTO activity_logs (user_id, action, details, ip_address) 
              VALUES ($user_id_value, '$action', '$details', '$ip_address')";
    
    return mysqli_query($conn, $query);
}

/**
 * Calculate exam score
 * @param array $user_answers User's answers array
 * @param array $correct_answers Correct answers array
 * @return array Score details
 */
function calculateExamScore($user_answers, $correct_answers) {
    $correct_count = 0;
    $total_questions = count($correct_answers);
    $incorrect_answers = [];
    
    foreach ($user_answers as $question_id => $user_choice_id) {
        if (isset($correct_answers[$question_id]) && $correct_answers[$question_id] == $user_choice_id) {
            $correct_count++;
        } else {
            $incorrect_answers[] = $question_id;
        }
    }
    
    $score_percentage = $total_questions > 0 ? round(($correct_count / $total_questions) * 100, 2) : 0;
    
    return [
        'score' => $correct_count,
        'total_questions' => $total_questions,
        'percentage' => $score_percentage,
        'incorrect_answers' => $incorrect_answers
    ];
}

/**
 * Get correct answers for an exam
 * @param int $exam_id Exam ID
 * @return array Array of question_id => correct_choice_id
 */
function getCorrectAnswers($exam_id) {
    global $conn;
    
    $exam_id = (int)$exam_id;
    $query = "SELECT q.id as question_id, c.id as correct_choice_id 
              FROM questions q 
              JOIN choices c ON q.id = c.question_id 
              WHERE q.exam_id = $exam_id AND c.is_correct = 1";
    
    $result = mysqli_query($conn, $query);
    $correct_answers = [];
    
    if ($result) {
        while ($row = mysqli_fetch_assoc($result)) {
            $correct_answers[$row['question_id']] = $row['correct_choice_id'];
        }
    }
    
    return $correct_answers;
}

/**
 * Cache questions for an exam
 * @param int $exam_id Exam ID
 * @return bool Success status
 */
function cacheExamQuestions($exam_id) {
    global $conn;
    
    $exam_id = (int)$exam_id;
    
    // Get questions with choices (without correct answer info)
    $query = "SELECT q.id, q.question_text, c.id as choice_id, c.choice_text 
              FROM questions q 
              JOIN choices c ON q.id = c.question_id 
              WHERE q.exam_id = $exam_id 
              ORDER BY q.id, c.id";
    
    $result = mysqli_query($conn, $query);
    $questions = [];
    
    if ($result) {
        while ($row = mysqli_fetch_assoc($result)) {
            $question_id = $row['id'];
            
            if (!isset($questions[$question_id])) {
                $questions[$question_id] = [
                    'id' => $question_id,
                    'question_text' => $row['question_text'],
                    'choices' => []
                ];
            }
            
            $questions[$question_id]['choices'][] = [
                'id' => $row['choice_id'],
                'choice_text' => $row['choice_text']
            ];
        }
    }
    
    // Convert to JSON
    $cache_json = json_encode(array_values($questions));
    
    // Update or insert cache
    $cache_query = "INSERT INTO question_cache (exam_id, cache_json) 
                    VALUES ($exam_id, '$cache_json') 
                    ON DUPLICATE KEY UPDATE cache_json = '$cache_json'";
    
    return mysqli_query($conn, $cache_query);
}

/**
 * Get cached questions for an exam
 * @param int $exam_id Exam ID
 * @return array|false Questions array on success, false on failure
 */
function getCachedQuestions($exam_id) {
    global $conn;
    
    $exam_id = (int)$exam_id;
    $query = "SELECT cache_json FROM question_cache WHERE exam_id = $exam_id";
    $result = mysqli_query($conn, $query);
    
    if ($result && mysqli_num_rows($result) > 0) {
        $row = mysqli_fetch_assoc($result);
        return json_decode($row['cache_json'], true);
    }
    
    return false;
}

/**
 * Clear question cache for an exam
 * @param int $exam_id Exam ID
 * @return bool Success status
 */
function clearQuestionCache($exam_id) {
    global $conn;
    
    $exam_id = (int)$exam_id;
    $query = "DELETE FROM question_cache WHERE exam_id = $exam_id";
    
    return mysqli_query($conn, $query);
}

/**
 * Format file size for display
 * @param int $bytes File size in bytes
 * @return string Formatted file size
 */
function formatFileSize($bytes) {
    $units = ['B', 'KB', 'MB', 'GB'];
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);
    
    $bytes /= pow(1024, $pow);
    
    return round($bytes, 2) . ' ' . $units[$pow];
}

/**
 * Generate random string
 * @param int $length String length
 * @return string Random string
 */
function generateRandomString($length = 10) {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $random_string = '';
    
    for ($i = 0; $i < $length; $i++) {
        $random_string .= $characters[rand(0, strlen($characters) - 1)];
    }
    
    return $random_string;
}

/**
 * Validate email format
 * @param string $email Email address
 * @return bool True if valid, false otherwise
 */
function isValidEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Get request method
 * @return string HTTP request method
 */
function getRequestMethod() {
    return $_SERVER['REQUEST_METHOD'];
}

/**
 * Get request body as JSON
 * @return array|false JSON data on success, false on failure
 */
function getJsonInput() {
    $input = file_get_contents('php://input');
    return json_decode($input, true);
}

/**
 * Get request parameters (GET or POST)
 * @return array Request parameters
 */
function getRequestParams() {
    if (getRequestMethod() === 'GET') {
        return $_GET;
    }
    
    return $_POST;
}

/**
 * Check if request is AJAX
 * @return bool True if AJAX request, false otherwise
 */
function isAjaxRequest() {
    return !empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
           strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest';
}

/**
 * Set CORS headers
 * @param string $origin Allowed origin (default: *)
 * @return void
 */
function setCorsHeaders($origin = '*') {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        exit(0);
    }
}
?>
