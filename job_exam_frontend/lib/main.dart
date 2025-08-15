import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/env_config.dart';
import 'core/services/local_storage.dart';
import 'core/services/storage_utils.dart';
import 'core/providers/auth_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/routes/app_router.dart';
import 'core/constants/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Local Storage
  await LocalStorageService.init();

  // Initialize Environment Config
  await EnvConfig.init();

  // Note: Storage health check removed to prevent startup issues
  // Storage will be checked when needed during app operation

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: EnvConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        builder: (context, child) {
          return Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // Set context for notifications after MaterialApp is built
              WidgetsBinding.instance.addPostFrameCallback((_) {
                authProvider.setContext(context);
              });
              return child!;
            },
          );
        },
      ),
    );
  }
}
