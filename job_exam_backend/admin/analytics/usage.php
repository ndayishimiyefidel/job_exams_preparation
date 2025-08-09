<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow GET method
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendErrorResponse('Method not allowed', 405);
}

// Get date range parameters
$start_date = isset($_GET['start_date']) ? $_GET['start_date'] : date('Y-m-d', strtotime('-30 days'));
$end_date = isset($_GET['end_date']) ? $_GET['end_date'] : date('Y-m-d');

// Validate dates
if (!strtotime($start_date) || !strtotime($end_date)) {
    sendErrorResponse('Invalid date format. Use YYYY-MM-DD');
}

$start_date = sanitizeInput($start_date);
$end_date = sanitizeInput($end_date);

// Get popular exams
$popular_exams_query = "SELECT e.id, e.title, p.title as position_title, e.is_paid, e.price,
                        COUNT(r.id) as attempt_count,
                        AVG(r.score) as avg_score,
                        COUNT(DISTINCT r.user_id) as unique_users
                        FROM exams e
                        LEFT JOIN positions p ON e.position_id = p.id
                        LEFT JOIN results r ON e.id = r.exam_id 
                        AND r.taken_at BETWEEN '$start_date 00:00:00' AND '$end_date 23:59:59'
                        GROUP BY e.id
                        ORDER BY attempt_count DESC
                        LIMIT 10";

$popular_exams_result = mysqli_query($conn, $popular_exams_query);
$popular_exams = [];

while ($row = mysqli_fetch_assoc($popular_exams_result)) {
    $popular_exams[] = [
        'id' => (int)$row['id'],
        'title' => $row['title'],
        'position_title' => $row['position_title'],
        'is_paid' => (bool)$row['is_paid'],
        'price' => (float)$row['price'],
        'attempt_count' => (int)$row['attempt_count'],
        'avg_score' => round((float)$row['avg_score'], 2),
        'unique_users' => (int)$row['unique_users']
    ];
}

// Get revenue data
$revenue_query = "SELECT DATE(p.payment_date) as date,
                  COUNT(p.id) as payment_count,
                  SUM(p.amount) as total_revenue
                  FROM payments p
                  WHERE p.status = 'completed'
                  AND p.payment_date BETWEEN '$start_date 00:00:00' AND '$end_date 23:59:59'
                  GROUP BY DATE(p.payment_date)
                  ORDER BY date";

$revenue_result = mysqli_query($conn, $revenue_query);
$revenue_data = [];

while ($row = mysqli_fetch_assoc($revenue_result)) {
    $revenue_data[] = [
        'date' => $row['date'],
        'payment_count' => (int)$row['payment_count'],
        'total_revenue' => (float)$row['total_revenue']
    ];
}

// Get user registration stats
$user_stats_query = "SELECT DATE(created_at) as date,
                     COUNT(*) as new_users
                     FROM users
                     WHERE role = 'user'
                     AND created_at BETWEEN '$start_date 00:00:00' AND '$end_date 23:59:59'
                     GROUP BY DATE(created_at)
                     ORDER BY date";

$user_stats_result = mysqli_query($conn, $user_stats_query);
$user_stats = [];

while ($row = mysqli_fetch_assoc($user_stats_result)) {
    $user_stats[] = [
        'date' => $row['date'],
        'new_users' => (int)$row['new_users']
    ];
}

// Get summary statistics
$summary_query = "SELECT 
                  (SELECT COUNT(*) FROM users WHERE role = 'user') as total_users,
                  (SELECT COUNT(*) FROM results WHERE taken_at BETWEEN '$start_date 00:00:00' AND '$end_date 23:59:59') as total_attempts,
                  (SELECT COUNT(DISTINCT user_id) FROM results WHERE taken_at BETWEEN '$start_date 00:00:00' AND '$end_date 23:59:59') as active_users,
                  (SELECT SUM(amount) FROM payments WHERE status = 'completed' AND payment_date BETWEEN '$start_date 00:00:00' AND '$end_date 23:59:59') as total_revenue,
                  (SELECT COUNT(*) FROM payments WHERE status = 'completed' AND payment_date BETWEEN '$start_date 00:00:00' AND '$end_date 23:59:59') as total_payments";

$summary_result = mysqli_query($conn, $summary_query);
$summary = mysqli_fetch_assoc($summary_result);

$analytics = [
    'date_range' => [
        'start_date' => $start_date,
        'end_date' => $end_date
    ],
    'summary' => [
        'total_users' => (int)$summary['total_users'],
        'total_attempts' => (int)$summary['total_attempts'],
        'active_users' => (int)$summary['active_users'],
        'total_revenue' => (float)$summary['total_revenue'],
        'total_payments' => (int)$summary['total_payments']
    ],
    'popular_exams' => $popular_exams,
    'revenue_data' => $revenue_data,
    'user_stats' => $user_stats
];

sendSuccessResponse($analytics, 'Analytics data retrieved successfully');
?>
