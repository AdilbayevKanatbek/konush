abstract final class AppConfig {
  static const enableDevOtp = bool.fromEnvironment(
    'ENABLE_DEV_OTP',
    defaultValue: true,
  );
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://147.45.157.226.nip.io/api/v1',
  );
  static const webSocketUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://147.45.157.226.nip.io/ws',
  );
  static const mediaBaseUrl = String.fromEnvironment(
    'MEDIA_BASE_URL',
    defaultValue: 'http://media.147.45.157.226.nip.io',
  );
}
