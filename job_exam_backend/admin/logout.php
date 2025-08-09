<?php
require_once '../includes/auth.php';
require_once '../includes/helpers.php';

// Check if user is logged in
$current_user = getCurrentUser();
if ($current_user) {
    // Log activity before ending session
    logActivity($current_user['id'], 'admin_logout', 'Admin logged out');
    
    // End user session
    endUserSession();
    
    sendSuccessResponse(null, 'Logout successful');
} else {
    sendErrorResponse('No active session', 401);
}
?>
