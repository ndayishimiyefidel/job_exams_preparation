# 🎯 Notification System Guide

## Overview

The Job Exam Frontend now includes a comprehensive, reusable notification system that provides consistent user feedback across the entire application. This system supports multiple notification types, customizable actions, and predefined messages for common scenarios.

## 🚀 Features

### ✅ **Multiple Notification Types**
- **Success**: Green notifications for successful operations
- **Error**: Red notifications for errors and failures
- **Warning**: Orange notifications for warnings and cautions
- **Info**: Blue notifications for informational messages
- **Loading**: Progress indicators for ongoing operations
- **Toast**: Simple, short-duration messages

### ✅ **Reusable Across App**
- Centralized notification service
- Consistent styling and behavior
- Easy to use from any screen
- Predefined messages for common scenarios

### ✅ **Customizable Actions**
- Action buttons on notifications
- Custom callbacks for action handling
- Retry functionality for failed operations
- Dismiss options

### ✅ **Enhanced User Experience**
- User-friendly error messages
- Clear success confirmations
- Informative warnings
- Loading states with feedback

## 📋 Usage Examples

### Basic Notifications

```dart
// Success notification
NotificationService.showSuccess(
  context: context,
  message: 'Operation completed successfully!',
);

// Error notification
NotificationService.showError(
  context: context,
  message: 'Something went wrong. Please try again.',
);

// Warning notification
NotificationService.showWarning(
  context: context,
  message: 'Please proceed with caution.',
);

// Info notification
NotificationService.showInfo(
  context: context,
  message: 'This is an informational message.',
);
```

### Notifications with Actions

```dart
// Error with retry action
NotificationService.showError(
  context: context,
  message: 'Failed to load data.',
  showAction: true,
  actionLabel: 'Retry',
  onActionPressed: () {
    // Retry logic here
    loadData();
  },
);

// Success with OK action
NotificationService.showSuccess(
  context: context,
  message: 'Data saved successfully!',
  showAction: true,
  actionLabel: 'OK',
);
```

### Loading Notifications

```dart
// Show loading
NotificationService.showLoading(
  context: context,
  message: 'Loading data...',
);

// Dismiss loading and show success
Future.delayed(const Duration(seconds: 2), () {
  NotificationService.dismissAll(context);
  NotificationService.showSuccess(
    context: context,
    message: 'Data loaded successfully!',
  );
});
```

### Toast Messages

```dart
// Simple toast message
NotificationService.showToast(
  context: context,
  message: 'Quick notification!',
  type: NotificationType.success,
);
```

## 🎨 Predefined Messages

### Authentication Messages
```dart
NotificationMessages.loginSuccess      // "Welcome back! Login successful."
NotificationMessages.loginFailed       // "Login failed. Please check your credentials."
NotificationMessages.registerSuccess   // "Account created successfully!"
NotificationMessages.registerFailed    // "Registration failed. Please try again."
NotificationMessages.logoutSuccess     // "Logged out successfully."
NotificationMessages.sessionExpired    // "Your session has expired. Please login again."
```

### Network Messages
```dart
NotificationMessages.networkError      // "Connection error. Please check your internet connection."
NotificationMessages.serverError       // "Server error. Please try again later."
NotificationMessages.timeoutError      // "Request timed out. Please try again."
NotificationMessages.serviceUnavailable // "Service temporarily unavailable."
```

### Form Validation Messages
```dart
NotificationMessages.requiredField     // "This field is required."
NotificationMessages.invalidEmail      // "Please enter a valid email address."
NotificationMessages.invalidPassword   // "Password must be at least 6 characters."
NotificationMessages.passwordMismatch  // "Passwords do not match."
NotificationMessages.invalidPhone      // "Please enter a valid phone number."
```

### Data Operation Messages
```dart
NotificationMessages.dataSaved         // "Data saved successfully."
NotificationMessages.dataUpdated       // "Data updated successfully."
NotificationMessages.dataDeleted       // "Data deleted successfully."
NotificationMessages.dataLoadError     // "Failed to load data. Please try again."
NotificationMessages.dataSaveError     // "Failed to save data. Please try again."
```

### File Operation Messages
```dart
NotificationMessages.fileUploadSuccess // "File uploaded successfully."
NotificationMessages.fileUploadFailed  // "File upload failed. Please try again."
NotificationMessages.fileDownloadSuccess // "File downloaded successfully."
NotificationMessages.fileDownloadFailed  // "File download failed. Please try again."
```

### General Messages
```dart
NotificationMessages.operationSuccess  // "Operation completed successfully."
NotificationMessages.operationFailed   // "Operation failed. Please try again."
NotificationMessages.permissionDenied  // "Permission denied. Please check your settings."
NotificationMessages.comingSoon        // "This feature is coming soon!"
NotificationMessages.maintenanceMode   // "System is under maintenance. Please try again later."
```

## 🔧 Predefined Actions

```dart
NotificationActions.retry      // "Retry"
NotificationActions.tryAgain   // "Try Again"
NotificationActions.dismiss    // "Dismiss"
NotificationActions.ok         // "OK"
NotificationActions.cancel     // "Cancel"
NotificationActions.settings   // "Settings"
NotificationActions.login      // "Login"
NotificationActions.register   // "Register"
```

## 🎯 Integration with AuthProvider

The AuthProvider has been updated to use the notification system:

### Automatic Notifications
- **Login Success**: Shows success message when user logs in
- **Login Error**: Shows error with retry action
- **Registration Success**: Shows success message
- **Registration Error**: Shows error with retry action
- **Logout Success**: Shows confirmation message
- **Session Expired**: Shows warning to re-login

### Context Setup
```dart
// In main.dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  authProvider.setContext(context);
});
```

## 🎨 Customization Options

### Duration
```dart
NotificationService.showSuccess(
  context: context,
  message: 'Custom duration message',
  duration: const Duration(seconds: 10), // Custom duration
);
```

### Custom Styling
The notification system uses the app's color scheme:
- **Success**: `AppColors.success` (Green)
- **Error**: `AppColors.error` (Red)
- **Warning**: `AppColors.warning` (Orange)
- **Info**: `AppColors.info` (Blue)
- **Loading**: `AppColors.primary` (Primary color)

### Custom Actions
```dart
NotificationService.showNotification(
  context: context,
  message: 'Custom notification',
  type: NotificationType.info,
  duration: const Duration(seconds: 8),
  showAction: true,
  actionLabel: 'Custom Action',
  onActionPressed: () {
    // Custom action logic
    print('Custom action triggered!');
  },
);
```

## 🔍 Debug Features

### Console Logging
The notification system works with the existing debug logging:
```
🔐 [AUTH] Attempting login with email: user@example.com
📡 [AUTH] Login API Response: {success: true, ...}
✅ [AUTH] Login successful for user: John Doe (ID: 1, Role: user)
```

### Error Tracking
- Detailed error messages in console
- User-friendly messages in notifications
- Action buttons for error recovery
- Retry functionality for failed operations

## 📱 Demo Screen

A demo screen is available at `NotificationDemoScreen` that showcases all notification types and features. You can navigate to it to test the notification system.

## 🚀 Best Practices

### 1. **Use Predefined Messages**
```dart
// ✅ Good
NotificationService.showError(
  context: context,
  message: NotificationMessages.networkError,
);

// ❌ Avoid
NotificationService.showError(
  context: context,
  message: 'Network error occurred',
);
```

### 2. **Provide Action Buttons for Errors**
```dart
// ✅ Good
NotificationService.showError(
  context: context,
  message: NotificationMessages.dataLoadError,
  showAction: true,
  actionLabel: NotificationActions.retry,
  onActionPressed: () => retryOperation(),
);
```

### 3. **Show Loading States**
```dart
// ✅ Good
NotificationService.showLoading(context: context, message: 'Loading...');
// ... perform operation
NotificationService.dismissAll(context);
NotificationService.showSuccess(context: context, message: 'Success!');
```

### 4. **Use Appropriate Duration**
- **Success**: 3 seconds (default)
- **Error**: 5 seconds (default)
- **Warning**: 4 seconds (default)
- **Info**: 4 seconds (default)
- **Loading**: 2 seconds (default)

### 5. **Handle Context Properly**
```dart
// ✅ Good - Set context in main.dart
authProvider.setContext(context);

// ✅ Good - Check context before showing notifications
if (_context != null) {
  NotificationService.showSuccess(
    context: _context!,
    message: 'Success!',
  );
}
```

## 🎉 Benefits

1. **Consistent UX**: All notifications look and behave the same
2. **Easy Maintenance**: Centralized notification logic
3. **User-Friendly**: Clear, actionable messages
4. **Developer-Friendly**: Simple API with predefined messages
5. **Accessible**: Proper contrast and readable text
6. **Responsive**: Works on all screen sizes
7. **Debug-Friendly**: Detailed logging for troubleshooting

## 🔧 Future Enhancements

- [ ] Sound notifications
- [ ] Push notifications
- [ ] Notification history
- [ ] Custom notification themes
- [ ] Notification preferences
- [ ] Batch notifications
- [ ] Notification queuing

---

**🎯 The notification system is now fully integrated and ready to provide excellent user feedback across your entire application!**
