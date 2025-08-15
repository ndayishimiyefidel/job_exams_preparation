import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/positions/positions_screen.dart';
import '../screens/exams/exams_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/positions':
        return MaterialPageRoute(builder: (_) => const PositionsScreen());
      case '/exams':
        final args = settings.arguments as Map<String, dynamic>?;
        final positionTitle = args?['positionTitle'] as String? ?? 'Exams';
        return MaterialPageRoute(
          builder: (_) => ExamsScreen(positionTitle: positionTitle),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
}
