class AppConfig {
  /// Ubah sesuai alamat backend Laravel.
  /// - Emulator Android : http://10.0.2.2:8000/api
  /// - iOS simulator    : http://127.0.0.1:8000/api
  /// - HP fisik         : http://<IP-LAN-komputer>:8000/api
  /// Bisa juga lewat: flutter run --dart-define=API_BASE_URL=http://...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
}
