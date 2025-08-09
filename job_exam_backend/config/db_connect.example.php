<?php
// Database connection configuration
// Copy this file to db_connect.php and update with your database credentials

define('DB_HOST', 'localhost');
define('DB_USER', 'your_username');
define('DB_PASS', 'your_password');
define('DB_NAME', 'job_exam_system');

// Create connection
$conn = mysqli_connect(DB_HOST, DB_USER, DB_PASS, DB_NAME);

// Check connection
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

// Set charset to utf8
mysqli_set_charset($conn, "utf8");

// Function to close connection
function closeConnection($conn) {
    mysqli_close($conn);
}

// Function to escape strings
function escapeString($conn, $string) {
    return mysqli_real_escape_string($conn, $string);
}
?>
