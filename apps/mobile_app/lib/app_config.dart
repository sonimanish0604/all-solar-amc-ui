class AppConfig {
  static final Uri apiBaseUri = Uri.parse(
    const String.fromEnvironment(
      'SOLAR_API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000',
    ),
  );

  static String get apiBaseLabel => apiBaseUri.toString();
}
