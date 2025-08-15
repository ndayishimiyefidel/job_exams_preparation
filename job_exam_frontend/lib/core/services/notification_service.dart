import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Show notification with custom styling
  static void showNotification({
    required BuildContext context,
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 4),
    bool showAction = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          _getIcon(type),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _getBackgroundColor(type),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: duration,
      action: showAction && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onActionPressed ?? () {},
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Success notification
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    bool showAction = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    showNotification(
      context: context,
      message: message,
      type: NotificationType.success,
      duration: duration,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Error notification
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 5),
    bool showAction = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    showNotification(
      context: context,
      message: message,
      type: NotificationType.error,
      duration: duration,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Warning notification
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    bool showAction = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    showNotification(
      context: context,
      message: message,
      type: NotificationType.warning,
      duration: duration,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Info notification
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    bool showAction = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    showNotification(
      context: context,
      message: message,
      type: NotificationType.info,
      duration: duration,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Loading notification (with progress indicator)
  static void showLoading({
    required BuildContext context,
    required String message,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Dismiss all notifications
  static void dismissAll(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Show toast message (simpler notification)
  static void showToast({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: _getBackgroundColor(type),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Helper methods
  static Widget _getIcon(NotificationType type) {
    IconData iconData;
    Color iconColor = Colors.white;

    switch (type) {
      case NotificationType.success:
        iconData = Icons.check_circle;
        break;
      case NotificationType.error:
        iconData = Icons.error;
        break;
      case NotificationType.warning:
        iconData = Icons.warning;
        break;
      case NotificationType.info:
        iconData = Icons.info;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 20,
    );
  }

  static Color _getBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.info:
        return AppColors.info;
    }
  }
}

// Predefined messages for common scenarios
class NotificationMessages {
  // Authentication messages
  static const String loginSuccess = 'Welcome back! Login successful.';
  static const String loginFailed =
      'Login failed. Please check your credentials.';
  static const String registerSuccess = 'Account created successfully!';
  static const String registerFailed = 'Registration failed. Please try again.';
  static const String logoutSuccess = 'Logged out successfully.';
  static const String sessionExpired =
      'Your session has expired. Please login again.';

  // Network messages
  static const String networkError =
      'Connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String serviceUnavailable = 'Service temporarily unavailable.';

  // Form validation messages
  static const String requiredField = 'This field is required.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String invalidPassword =
      'Password must be at least 6 characters.';
  static const String passwordMismatch = 'Passwords do not match.';
  static const String invalidPhone = 'Please enter a valid phone number.';

  // Data operation messages
  static const String dataSaved = 'Data saved successfully.';
  static const String dataUpdated = 'Data updated successfully.';
  static const String dataDeleted = 'Data deleted successfully.';
  static const String dataLoadError = 'Failed to load data. Please try again.';
  static const String dataSaveError = 'Failed to save data. Please try again.';

  // File operation messages
  static const String fileUploadSuccess = 'File uploaded successfully.';
  static const String fileUploadFailed =
      'File upload failed. Please try again.';
  static const String fileDownloadSuccess = 'File downloaded successfully.';
  static const String fileDownloadFailed =
      'File download failed. Please try again.';

  // General messages
  static const String operationSuccess = 'Operation completed successfully.';
  static const String operationFailed = 'Operation failed. Please try again.';
  static const String permissionDenied =
      'Permission denied. Please check your settings.';
  static const String comingSoon = 'This feature is coming soon!';
  static const String maintenanceMode =
      'System is under maintenance. Please try again later.';
}

// Predefined actions
class NotificationActions {
  static const String retry = 'Retry';
  static const String tryAgain = 'Try Again';
  static const String dismiss = 'Dismiss';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String settings = 'Settings';
  static const String login = 'Login';
  static const String register = 'Register';
}
