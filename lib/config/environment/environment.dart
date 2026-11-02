class Environment {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://mavens-attendance-test-khashraf.fly.dev/api',
  );
}
