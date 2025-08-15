class EnvConfig {
  static const String baseUrl =
      'http://localhost/job_exams_preparation/job_exam_backend';
  static const String apiUrl = '$baseUrl/api';
  static const String adminUrl = '$baseUrl/admin';

  // AUTH Endpoints
  static const String loginEndpoint = '$apiUrl/auth/login.php';
  static const String registerEndpoint = '$apiUrl/auth/register.php';
  static const String logoutEndpoint = '$apiUrl/auth/logout.php';

  //USER ENDPOINTS
  static const String positionsEndpoint = '$apiUrl/positions.php';
  static const String examsEndpoint = '$apiUrl/exams.php';
  static const String questionsEndpoint = '$apiUrl/questions.php';
  static const String submitResultsEndpoint = '$apiUrl/submit_results.php';
  static const String resourcesEndpoint = '$apiUrl/resources.php';
  static const String paymentsEndpoint = '$apiUrl/payments.php';

  // Admin Endpoints
  static const String adminPositionsEndpoint = '$adminUrl/positions';
  static const String adminQuestionsEndpoint = '$adminUrl/questions';
  static const String adminExamsEndpoint = '$adminUrl/exams';
  static const String adminResourcesEndpoint = '$adminUrl/resources';
  static const String adminAnalyticsEndpoint = '$adminUrl/analytics';

  // App Configuration
  static const String appName = 'Job Exam Prep';
  static const String appVersion = '1.0.0';
  static const int requestTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;

  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Cache Configuration
  static const int cacheExpiryHours = 24;
  static const int questionCacheExpiryHours = 168; // 1 week

  static Future<void> init() async {
    // Initialize any environment-specific configurations
    // This can be extended for different environments (dev, staging, prod)
  }
}
