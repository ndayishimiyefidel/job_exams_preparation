<?php
require_once __DIR__ . '/../config/db_connect.php';

/**
 * Authenticate user login
 * @param string $email User email
 * @param string $password User password
 * @return array|false User data on success, false on failure
 */
function authenticateUser($email, $password) {
    global $conn;
    
    $email = escapeString($conn, $email);
    $query = "SELECT id, name, email,phone, password, role FROM users WHERE email = '$email'";
    $result = mysqli_query($conn, $query);
    
    if ($result && mysqli_num_rows($result) > 0) {
        $user = mysqli_fetch_assoc($result);
        
        if (password_verify($password, $user['password'])) {
            unset($user['password']); // Don't return password
            return $user;
        }
    }
    
    return false;
}

/**
 * Generate API token for mobile app
 * @param int $user_id User ID
 * @return string|false Token on success, false on failure
 */
function generateApiToken($user_id) {
    global $conn;
    
    $user_id = (int)$user_id;
    $token = bin2hex(random_bytes(32)); // 64 character hex string
    $expires_at = date('Y-m-d H:i:s', strtotime('+30 days'));
    
    // Delete existing tokens for this user
    $delete_query = "DELETE FROM api_tokens WHERE user_id = $user_id";
    mysqli_query($conn, $delete_query);
    
    // Insert new token
    $insert_query = "INSERT INTO api_tokens (user_id, token, expires_at) VALUES ($user_id, '$token', '$expires_at')";
    
    if (mysqli_query($conn, $insert_query)) {
        return $token;
    }
    
    return false;
}

/**
 * Validate API token
 * @param string $token API token
 * @return array|false User data on success, false on failure
 */
function validateApiToken($token) {
    global $conn;
    
    $token = escapeString($conn, $token);
    $current_time = date('Y-m-d H:i:s');
    
    $query = "SELECT u.id, u.name, u.email, u.role, at.token 
              FROM users u 
              JOIN api_tokens at ON u.id = at.user_id 
              WHERE at.token = '$token' AND at.expires_at > '$current_time'";
    
    $result = mysqli_query($conn, $query);
    
    if ($result && mysqli_num_rows($result) > 0) {
        return mysqli_fetch_assoc($result);
    }
    
    return false;
}

/**
 * Invalidate API token (logout)
 * @param string $token API token
 * @return bool Success status
 */
function invalidateApiToken($token) {
    global $conn;
    
    $token = escapeString($conn, $token);
    $query = "DELETE FROM api_tokens WHERE token = '$token'";
    
    return mysqli_query($conn, $query);
}

/**
 * Check if user is admin
 * @param array $user User data array
 * @return bool True if admin, false otherwise
 */
function isAdmin($user) {
    return isset($user['role']) && $user['role'] === 'admin';
}

/**
 * Require admin authentication
 * @param array $user User data array
 * @return void Exits with error if not admin
 */
function requireAdmin($user) {
    if (!isAdmin($user)) {
        sendErrorResponse('Admin access required', 403);
    }
}

/**
 * Get current user from session (for web admin)
 * @return array|false User data on success, false on failure
 */
function getCurrentUser() {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }

    if (isset($_SESSION['user_id'])) {
        global $conn;
        $user_id = (int)$_SESSION['user_id'];
        $query = "SELECT id, name, email, phone, role FROM users WHERE id = $user_id";
        $result = mysqli_query($conn, $query);

        if ($result && mysqli_num_rows($result) > 0) {
            return mysqli_fetch_assoc($result);
        }
    }

    return false;
}

/**
 * Get current user from session or API token (for admin endpoints)
 * @return array|false User data on success, false on failure
 */
function getCurrentUserOrToken() {
    // First try session-based authentication (for web admin)
    $user = getCurrentUser();
    if ($user) {
        return $user;
    }
    
    // Then try API token authentication (for API calls)
    $headers = getallheaders();
    if (!$headers) {
        // Fallback for servers that don't support getallheaders()
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (substr($name, 0, 5) == 'HTTP_') {
                $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
            }
        }
    }
    $auth_header = isset($headers['Authorization']) ? $headers['Authorization'] : '';
    
    if (!empty($auth_header) && strpos($auth_header, 'Bearer ') === 0) {
        $token = substr($auth_header, 7);
        $user = validateApiToken($token);
        if ($user) {
            return $user;
        }
    }
    
    return false;
}

/**
 * Start user session (for web admin)
 * @param array $user User data array
 * @return void
 */
function startUserSession($user) {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    $_SESSION['user_id'] = $user['id'];
    $_SESSION['user_name'] = $user['name'];
    $_SESSION['user_role'] = $user['role'];
    $_SESSION['user_phone'] = $user['phone'];
}

/**
 * End user session (for web admin)
 * @return void
 */
function endUserSession() {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    session_destroy();
}

/**
 * Hash password using bcrypt
 * @param string $password Plain text password
 * @return string Hashed password
 */
function hashPassword($password) {
    return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
}

/**
 * Create new user account
 * @param string $name User name
 * @param string $email User email
 * @param string $password Plain text password
 * @param string $role User role (default: 'user')
 * @param string $phone User phone number (optional)
 * @return int|false User ID on success, false on failure
 */
function createUser($name, $email, $password, $role = 'user', $phone = null) {
    global $conn;
    
    $name = escapeString($conn, $name);
    $email = escapeString($conn, $email);
    $phone = $phone ? escapeString($conn, $phone) : 'NULL';
    $hashed_password = hashPassword($password);
    $role = escapeString($conn, $role);
    
    $query = "INSERT INTO users (name, email, phone, password, role) VALUES ('$name', '$email', " . 
             ($phone !== 'NULL' ? "'$phone'" : "NULL") . ", '$hashed_password', '$role')";
    
    if (mysqli_query($conn, $query)) {
        return mysqli_insert_id($conn);
    }
    
    return false;
}

/**
 * Check if email already exists
 * @param string $email Email to check
 * @return bool True if exists, false otherwise
 */
function emailExists($email) {
    global $conn;
    
    $email = escapeString($conn, $email);
    $query = "SELECT id FROM users WHERE email = '$email'";
    $result = mysqli_query($conn, $query);
    
    return mysqli_num_rows($result) > 0;
}
?>
