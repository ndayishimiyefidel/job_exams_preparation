import 'package:flutter/material.dart';
import '../services/simple_api_service.dart';
import '../services/local_storage.dart';
import '../services/notification_service.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;
  BuildContext? _context;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Set context for notifications
  void setContext(BuildContext context) {
    _context = context;
  }

  // Initialize auth state
  Future<void> initialize() async {
    _setLoading(true);

    try {
      print('🔐 [AUTH] Initializing authentication state...');
      final user = LocalStorageService.getUser();
      final token = await LocalStorageService.getAuthToken();

      if (user != null && token != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        print('✅ [AUTH] User authenticated: ${user.name} (ID: ${user.id})');

        // Only show notification if context is available and app is fully initialized
        if (_context != null && _context!.mounted) {
          try {
            NotificationService.showSuccess(
              context: _context!,
              message: NotificationMessages.loginSuccess,
            );
          } catch (notificationError) {
            print('⚠️ [AUTH] Could not show notification: $notificationError');
          }
        }
      } else {
        _status = AuthStatus.unauthenticated;
        print('ℹ️ [AUTH] User not authenticated - no stored credentials found');
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to initialize authentication: $e';
      print('❌ [AUTH] Initialization error: $e');

      // Only show notification if context is available and app is fully initialized
      if (_context != null && _context!.mounted) {
        try {
          NotificationService.showError(
            context: _context!,
            message: 'Failed to initialize authentication: $e',
          );
        } catch (notificationError) {
          print('⚠️ [AUTH] Could not show notification: $notificationError');
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 [AUTH] Attempting login with email: $email');

      if (_context != null) {
        NotificationService.showLoading(
          context: _context!,
          message: 'Logging in...',
        );
      }

      final response = await SimpleApiService.login(email, password);

      print('📡 [AUTH] Login API Response: $response');

      if (response['success'] == true) {
        try {
          final userData = response['data']['user'];
          final token = response['data']['api_token'];

          print('🔍 [AUTH] Parsing user data: $userData');

          _user = UserModel.fromJson(userData);
          await LocalStorageService.saveUser(_user!);
          await LocalStorageService.saveAuthToken(token);

          _status = AuthStatus.authenticated;
          print(
              '✅ [AUTH] Login successful for user: ${_user!.name} (ID: ${_user!.id}, Role: ${_user!.role})');

          if (_context != null) {
            NotificationService.showSuccess(
              context: _context!,
              message: NotificationMessages.loginSuccess,
            );
          }

          notifyListeners();
          return true;
        } catch (parseError) {
          _errorMessage = 'Failed to parse user data: $parseError';
          _status = AuthStatus.error;
          print('❌ [AUTH] User data parsing error: $parseError');
          print('🔍 [AUTH] Raw user data: ${response['data']['user']}');

          if (_context != null) {
            NotificationService.showError(
              context: _context!,
              message:
                  'Login successful but there was an issue processing your account data. Please try again.',
              showAction: true,
              actionLabel: NotificationActions.tryAgain,
              onActionPressed: () => login(email, password),
            );
          }

          notifyListeners();
          return false;
        }
      } else {
        final errorMsg = response['message'] ?? 'Login failed';
        _errorMessage = _getUserFriendlyMessage(errorMsg);
        _status = AuthStatus.error;
        print('❌ [AUTH] Login failed: $errorMsg');

        if (_context != null) {
          NotificationService.showError(
            context: _context!,
            message: _errorMessage!,
            showAction: true,
            actionLabel: NotificationActions.tryAgain,
            onActionPressed: () => login(email, password),
          );
        }

        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _getUserFriendlyMessage('Network error: $e');
      _status = AuthStatus.error;
      print('❌ [AUTH] Login error: $e');

      if (_context != null) {
        NotificationService.showError(
          context: _context!,
          message: _errorMessage!,
          showAction: true,
          actionLabel: NotificationActions.retry,
          onActionPressed: () => login(email, password),
        );
      }

      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register
  Future<bool> register(
      String name, String email, String password, String? phone) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 [AUTH] Attempting registration with email: $email');

      if (_context != null) {
        NotificationService.showLoading(
          context: _context!,
          message: 'Creating account...',
        );
      }

      final response =
          await SimpleApiService.register(name, email, password, phone);

      print('📡 [AUTH] Registration API Response: $response');

      if (response['success'] == true) {
        // Check if user data is returned (auto-login after registration)
        if (response['data'] != null && response['data']['user'] != null) {
          try {
            final userData = response['data']['user'];
            final token = response['data']['api_token'];

            print('🔍 [AUTH] Parsing registration user data: $userData');

            _user = UserModel.fromJson(userData);
            await LocalStorageService.saveUser(_user!);
            await LocalStorageService.saveAuthToken(token);

            _status = AuthStatus.authenticated;
            print(
                '✅ [AUTH] Registration and auto-login successful for user: ${_user!.name} (ID: ${_user!.id})');

            if (_context != null) {
              NotificationService.showSuccess(
                context: _context!,
                message: NotificationMessages.registerSuccess,
              );
            }

            notifyListeners();
            return true;
          } catch (parseError) {
            _errorMessage =
                'Registration successful but failed to auto-login: $parseError';
            _status = AuthStatus.unauthenticated;
            print(
                '⚠️ [AUTH] Registration successful but auto-login failed: $parseError');

            if (_context != null) {
              NotificationService.showWarning(
                context: _context!,
                message: 'Registration successful! Please login to continue.',
                showAction: true,
                actionLabel: NotificationActions.login,
              );
            }

            notifyListeners();
            return true;
          }
        } else {
          // Registration successful but no auto-login
          _status = AuthStatus.unauthenticated;
          print('✅ [AUTH] Registration successful. Please login.');

          if (_context != null) {
            NotificationService.showSuccess(
              context: _context!,
              message: NotificationMessages.registerSuccess,
            );
          }

          notifyListeners();
          return true;
        }
      } else {
        final errorMsg = response['message'] ?? 'Registration failed';
        _errorMessage = _getUserFriendlyMessage(errorMsg);
        _status = AuthStatus.error;
        print('❌ [AUTH] Registration failed: $errorMsg');

        if (_context != null) {
          NotificationService.showError(
            context: _context!,
            message: _errorMessage!,
            showAction: true,
            actionLabel: NotificationActions.tryAgain,
            onActionPressed: () => register(name, email, password, phone),
          );
        }

        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _getUserFriendlyMessage('Network error: $e');
      _status = AuthStatus.error;
      print('❌ [AUTH] Registration error: $e');

      if (_context != null) {
        NotificationService.showError(
          context: _context!,
          message: _errorMessage!,
          showAction: true,
          actionLabel: NotificationActions.retry,
          onActionPressed: () => register(name, email, password, phone),
        );
      }

      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update Profile
  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    _setLoading(true);

    try {
      print('🔐 [AUTH] Attempting to update profile...');

      final response = await SimpleApiService.updateProfile(name, email, phone);

      if (response['success'] == true) {
        // Update local user data
        if (_user != null) {
          _user = _user!.copyWith(
            name: name,
            email: email,
            phone: phone,
          );
          await LocalStorageService.saveUser(_user!);
        }

        print('✅ [AUTH] Profile updated successfully');
      } else {
        // Don't change authentication status for profile update errors
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('❌ [AUTH] Profile update error: $e');
      _errorMessage = _getUserFriendlyMessage(e.toString());
      // Ensure we don't change authentication status for profile update errors
      if (_status == AuthStatus.authenticated) {
        _status = AuthStatus.authenticated; // Keep authenticated
      }
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);

    try {
      print('🔐 [AUTH] Attempting to change password...');

      final response =
          await SimpleApiService.changePassword(currentPassword, newPassword);

      if (response['success'] == true) {
        print('✅ [AUTH] Password changed successfully');
      } else {
        // Don't change authentication status for password change errors
        throw Exception(response['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      print('❌ [AUTH] Password change error: $e');
      _errorMessage = _getUserFriendlyMessage(e.toString());
      // Ensure we don't change authentication status for password change errors
      if (_status == AuthStatus.authenticated) {
        _status = AuthStatus.authenticated; // Keep authenticated
      }
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Delete Account
  Future<void> deleteAccount({required String password}) async {
    _setLoading(true);

    try {
      print('🔐 [AUTH] Attempting to delete account...');

      if (_context != null) {
        NotificationService.showLoading(
          context: _context!,
          message: 'Deleting account...',
        );
      }

      final response = await SimpleApiService.deleteAccount(password);

      if (response['success'] == true) {
        // Clear local data
        await LocalStorageService.clearUser();
        await LocalStorageService.clearAuthToken();

        _user = null;
        _status = AuthStatus.unauthenticated;
        _clearError();

        print('✅ [AUTH] Account deleted successfully');

        if (_context != null) {
          NotificationService.showSuccess(
            context: _context!,
            message: 'Account deleted successfully!',
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      print('❌ [AUTH] Account deletion error: $e');
      _errorMessage = _getUserFriendlyMessage(e.toString());

      if (_context != null) {
        NotificationService.showError(
          context: _context!,
          message: _errorMessage!,
        );
      }
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      print('🔐 [AUTH] Attempting logout...');

      if (_context != null) {
        NotificationService.showLoading(
          context: _context!,
          message: 'Logging out...',
        );
      }

      await SimpleApiService.logout();
      print('✅ [AUTH] Logout API call successful');
    } catch (e) {
      // Continue with logout even if API call fails
      print('⚠️ [AUTH] Logout API error (continuing with local logout): $e');
    }

    await LocalStorageService.clearUser();
    await LocalStorageService.clearAuthToken();

    _user = null;
    _status = AuthStatus.unauthenticated;
    _clearError();

    print('✅ [AUTH] User logged out successfully');

    if (_context != null) {
      NotificationService.showSuccess(
        context: _context!,
        message: NotificationMessages.logoutSuccess,
      );
    }

    notifyListeners();
    _setLoading(false);
  }

  // Clear error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      // Don't change status to loading if we're already authenticated
      // This prevents profile updates from affecting authentication status
      if (_status != AuthStatus.authenticated) {
        _status = AuthStatus.loading;
      }
    }
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
  }

  // Convert technical error messages to user-friendly messages
  String _getUserFriendlyMessage(String technicalMessage) {
    if (technicalMessage.contains('Invalid email or password')) {
      return NotificationMessages.loginFailed;
    } else if (technicalMessage.contains('Email already exists')) {
      return 'An account with this email already exists. Please use a different email or try logging in.';
    } else if (technicalMessage.contains('Network error')) {
      return NotificationMessages.networkError;
    } else if (technicalMessage.contains('Failed to parse user data')) {
      return 'Login successful but there was an issue processing your account data. Please try again.';
    } else if (technicalMessage.contains('timeout')) {
      return NotificationMessages.timeoutError;
    } else if (technicalMessage.contains('404')) {
      return NotificationMessages.serviceUnavailable;
    } else if (technicalMessage.contains('500')) {
      return NotificationMessages.serverError;
    } else {
      return technicalMessage;
    }
  }
}
