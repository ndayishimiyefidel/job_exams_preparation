import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/app_colors.dart';

class NotificationDemoScreen extends StatelessWidget {
  const NotificationDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Demo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Notification Service Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap the buttons below to see different types of notifications:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Success Notifications
            _buildSectionTitle('Success Notifications'),
            ElevatedButton(
              onPressed: () => NotificationService.showSuccess(
                context: context,
                message: NotificationMessages.loginSuccess,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Success Message'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => NotificationService.showSuccess(
                context: context,
                message: NotificationMessages.dataSaved,
                showAction: true,
                actionLabel: NotificationActions.ok,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Success with Action'),
            ),
            const SizedBox(height: 20),

            // Error Notifications
            _buildSectionTitle('Error Notifications'),
            ElevatedButton(
              onPressed: () => NotificationService.showError(
                context: context,
                message: NotificationMessages.networkError,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Error Message'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => NotificationService.showError(
                context: context,
                message: NotificationMessages.dataLoadError,
                showAction: true,
                actionLabel: NotificationActions.retry,
                onActionPressed: () {
                  NotificationService.showInfo(
                    context: context,
                    message: 'Retry action triggered!',
                  );
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Error with Retry Action'),
            ),
            const SizedBox(height: 20),

            // Warning Notifications
            _buildSectionTitle('Warning Notifications'),
            ElevatedButton(
              onPressed: () => NotificationService.showWarning(
                context: context,
                message:
                    'This is a warning message. Please proceed with caution.',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Warning Message'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => NotificationService.showWarning(
                context: context,
                message: 'Session will expire soon. Do you want to extend?',
                showAction: true,
                actionLabel: 'Extend',
                onActionPressed: () {
                  NotificationService.showSuccess(
                    context: context,
                    message: 'Session extended successfully!',
                  );
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Warning with Action'),
            ),
            const SizedBox(height: 20),

            // Info Notifications
            _buildSectionTitle('Info Notifications'),
            ElevatedButton(
              onPressed: () => NotificationService.showInfo(
                context: context,
                message: 'This is an informational message.',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Info Message'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => NotificationService.showInfo(
                context: context,
                message: 'New features are available!',
                showAction: true,
                actionLabel: 'Learn More',
                onActionPressed: () {
                  NotificationService.showToast(
                    context: context,
                    message: 'Opening feature guide...',
                    type: NotificationType.info,
                  );
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
              ),
              child: const Text('Info with Action'),
            ),
            const SizedBox(height: 20),

            // Loading and Toast
            _buildSectionTitle('Loading & Toast'),
            ElevatedButton(
              onPressed: () {
                NotificationService.showLoading(
                  context: context,
                  message: 'Loading data...',
                );
                // Simulate loading
                Future.delayed(const Duration(seconds: 2), () {
                  NotificationService.dismissAll(context);
                  NotificationService.showSuccess(
                    context: context,
                    message: 'Data loaded successfully!',
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Loading'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => NotificationService.showToast(
                context: context,
                message: 'This is a toast message!',
                type: NotificationType.success,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Toast'),
            ),
            const SizedBox(height: 20),

            // Custom Notifications
            _buildSectionTitle('Custom Notifications'),
            ElevatedButton(
              onPressed: () => NotificationService.showNotification(
                context: context,
                message: 'This is a custom notification with longer duration',
                type: NotificationType.info,
                duration: const Duration(seconds: 8),
                showAction: true,
                actionLabel: 'Dismiss',
                onActionPressed: () => NotificationService.dismissAll(context),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Custom Notification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
