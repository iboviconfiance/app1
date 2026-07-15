class AppConstants {
  /// En Docker : `/api` (proxy Nginx vers le backend)
  /// En local  : `http://localhost:3000/api`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '/api',
  );
}
