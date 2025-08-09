<?php
require_once '../includes/auth.php';
require_once '../includes/helpers.php';

// Allow CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Only allow GET method
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendErrorResponse('Method not allowed', 405);
}

// Get params
$exam_id = isset($_GET['exam_id']) ? (int)$_GET['exam_id'] : 0;
$forceRefresh = isset($_GET['refresh_cache']) && $_GET['refresh_cache'] == '1';
$shuffleChoices = !isset($_GET['shuffle']) || $_GET['shuffle'] == '1'; // default true
$seedParam = isset($_GET['seed']) ? (string)$_GET['seed'] : '';

if ($exam_id <= 0) {
    sendErrorResponse('Invalid exam ID');
}

// Check if exam exists
$exam_check = "SELECT e.*, p.title as position_title FROM exams e 
               LEFT JOIN positions p ON e.position_id = p.id 
               WHERE e.id = $exam_id";
$exam_result = mysqli_query($conn, $exam_check);

if (mysqli_num_rows($exam_result) == 0) {
    sendErrorResponse('Exam not found', 404);
}

$exam = mysqli_fetch_assoc($exam_result);

// Paid exam access control
$user = null;
if ($exam['is_paid']) {
    $auth_header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $token = str_replace('Bearer ', '', $auth_header);
    if (empty($token)) {
        sendErrorResponse('Login required for paid exams', 401);
    }
    $user = validateApiToken($token);
    if (!$user) {
        sendErrorResponse('Invalid or expired token', 401);
    }
    // Check purchase
    $payment_check = "SELECT id FROM payments WHERE user_id = {$user['id']} AND exam_id = $exam_id AND status = 'completed'";
    $payment_result = mysqli_query($conn, $payment_check);
    if (mysqli_num_rows($payment_result) == 0) {
        sendErrorResponse('Purchase required for this exam', 403);
    }
}

// Build deterministic seed if not provided (stable per user+exam or exam only)
$deterministicSeed = $seedParam !== '' ? $seedParam : (($user ? (string)$user['id'] : 'guest') . '-' . (string)$exam_id);

// Helper to deterministically shuffle choices without exposing randomness globally
$shuffleChoicesFn = function(array &$questions, string $seed) {
    foreach ($questions as &$q) {
        if (!isset($q['choices']) || !is_array($q['choices'])) continue;
        usort($q['choices'], function($a, $b) use ($seed) {
            $wa = crc32($seed . '-' . (string)($a['id'] ?? 0));
            $wb = crc32($seed . '-' . (string)($b['id'] ?? 0));
            // Ensure consistent ordering even if equal hashes
            if ($wa === $wb) {
                return ($a['id'] ?? 0) <=> ($b['id'] ?? 0);
            }
            return $wa <=> $wb;
        });
    }
};

// Return cached if available and not forcing refresh
if (!$forceRefresh) {
    $cache_query = "SELECT cache_json FROM question_cache WHERE exam_id = $exam_id AND last_updated > DATE_SUB(NOW(), INTERVAL 1 HOUR)";
    $cache_result = mysqli_query($conn, $cache_query);
    if ($cache_result && mysqli_num_rows($cache_result) > 0) {
        $cache_data = mysqli_fetch_assoc($cache_result);
        $cached_questions = json_decode($cache_data['cache_json'], true);
        if ($cached_questions) {
            if ($shuffleChoices) {
                $shuffleChoicesFn($cached_questions, $deterministicSeed);
            }
            sendSuccessResponse([
                'exam' => [
                    'id' => $exam['id'],
                    'title' => $exam['title'],
                    'position_title' => $exam['position_title'],
                    'is_paid' => (bool)$exam['is_paid'],
                    'price' => (float)$exam['price']
                ],
                'questions' => $cached_questions,
                'total_questions' => count($cached_questions),
                'cached' => true
            ], 'Questions retrieved successfully (cached)');
        }
    }
}

// Build fresh questions list (aggregate choices per question)
$query = "SELECT 
            q.id AS question_id,
            q.question_text,
            q.questionImageUrl,
            c.id AS choice_id,
            c.choice_text
          FROM questions q 
          LEFT JOIN choices c ON q.id = c.question_id 
          WHERE q.exam_id = $exam_id 
          ORDER BY q.id, c.id";

$result = mysqli_query($conn, $query);
if (!$result) {
    sendErrorResponse('Failed to fetch questions: ' . mysqli_error($conn));
}

$questionsById = [];
while ($row = mysqli_fetch_assoc($result)) {
    $qid = (int)$row['question_id'];
    if (!isset($questionsById[$qid])) {
        $questionsById[$qid] = [
            'id' => $qid,
            'question_text' => $row['question_text'],
            'questionImageUrl' => $row['questionImageUrl'] ?? null,
            'choices' => []
        ];
    }

    if (!empty($row['choice_id'])) {
        $questionsById[$qid]['choices'][] = [
            'id' => (int)$row['choice_id'],
            'choice_text' => $row['choice_text']
        ];
    }
}

$questions = array_values($questionsById);

// Update cache with unshuffled data only
$cache_json = mysqli_real_escape_string($conn, json_encode($questions));
$cache_update = "INSERT INTO question_cache (exam_id, cache_json) VALUES ($exam_id, '$cache_json') 
                 ON DUPLICATE KEY UPDATE cache_json = '$cache_json', last_updated = NOW()";
mysqli_query($conn, $cache_update);

// Shuffle final response if requested
if ($shuffleChoices) {
    $shuffleChoicesFn($questions, $deterministicSeed);
}

sendSuccessResponse([
    'exam' => [
        'id' => $exam['id'],
        'title' => $exam['title'],
        'position_title' => $exam['position_title'],
        'is_paid' => (bool)$exam['is_paid'],
        'price' => (float)$exam['price']
    ],
    'questions' => $questions,
    'total_questions' => count($questions),
    'cached' => false
], 'Questions retrieved successfully');
?>
