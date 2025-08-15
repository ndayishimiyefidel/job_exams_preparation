<?php
require_once 'config/db_connect.php';

echo "Checking database setup...\n";

// Check if users table exists
$result = mysqli_query($conn, "SHOW TABLES LIKE 'users'");
if (mysqli_num_rows($result) == 0) {
    echo "Database tables not found. Importing SQL file...\n";
    
    // Read and execute SQL file
    $sql = file_get_contents('job_exam_system.sql');
    if ($sql) {
        $queries = explode(';', $sql);
        foreach ($queries as $query) {
            $query = trim($query);
            if (!empty($query)) {
                if (mysqli_query($conn, $query)) {
                    echo "Query executed successfully\n";
                } else {
                    echo "Error executing query: " . mysqli_error($conn) . "\n";
                }
            }
        }
        echo "Database setup completed!\n";
    } else {
        echo "Could not read SQL file\n";
    }
} else {
    echo "Database tables already exist.\n";
}

// Check if admin user exists
$result = mysqli_query($conn, "SELECT * FROM users WHERE email = 'admin@jobexam.com'");
if (mysqli_num_rows($result) == 0) {
    echo "Admin user not found. Creating...\n";
    $hashed_password = password_hash('admin123', PASSWORD_DEFAULT);
    $sql = "INSERT INTO users (name, email, phone, password, role) VALUES ('Admin User', 'admin@jobexam.com', '+1234567890', '$hashed_password', 'admin')";
    if (mysqli_query($conn, $sql)) {
        echo "Admin user created successfully!\n";
    } else {
        echo "Error creating admin user: " . mysqli_error($conn) . "\n";
    }
} else {
    echo "Admin user already exists.\n";
}

// Test login
echo "\nTesting login with admin credentials...\n";
$email = 'admin@jobexam.com';
$password = 'admin123';

$stmt = mysqli_prepare($conn, "SELECT * FROM users WHERE email = ?");
mysqli_stmt_bind_param($stmt, "s", $email);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

if ($user = mysqli_fetch_assoc($result)) {
    if (password_verify($password, $user['password'])) {
        echo "Login test successful! Admin user can log in.\n";
    } else {
        echo "Password verification failed. Updating password...\n";
        $hashed_password = password_hash('admin123', PASSWORD_DEFAULT);
        $update_sql = "UPDATE users SET password = '$hashed_password' WHERE email = 'admin@jobexam.com'";
        if (mysqli_query($conn, $update_sql)) {
            echo "Password updated successfully!\n";
        } else {
            echo "Error updating password: " . mysqli_error($conn) . "\n";
        }
    }
} else {
    echo "Admin user not found in database.\n";
}

mysqli_close($conn);
echo "Database setup check completed!\n";
?>
