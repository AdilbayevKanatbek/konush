abstract final class AppConfig {
  static const enableDevOtp = bool.fromEnvironment(
    'ENABLE_DEV_OTP',
    defaultValue: true,
  );
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stage.konush.kg/api/v1',
  );
  static const webSocketUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://stage.konush.kg/ws',
  );
  static const mediaBaseUrl = String.fromEnvironment(
    'MEDIA_BASE_URL',
    defaultValue: 'https://media.stage.konush.kg',
  );
}
