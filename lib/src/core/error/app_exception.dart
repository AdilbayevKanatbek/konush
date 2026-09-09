class AppException implements Exception {
  const AppException(this.message, {this.code, this.details, this.statusCode});

  final String message;
  final String? code;
  final Object? details;
  final int? statusCode;

  @override
  String toString() => message;

  String get userMessage => switch (code) {
    'PHONE_EXISTS' => 'Этот номер телефона уже зарегистрирован',
    'INVALID_CREDENTIALS' => 'Неверный номер телефона или пароль',
    'INVALID_OTP' => 'Неверный или просроченный код',
    'USER_BANNED' => 'Аккаунт заблокирован',
    'UNAUTHORIZED' => 'Необходимо войти в аккаунт',
    'NOT_FOUND' => 'Данные не найдены',
    'FILE_TOO_LARGE' => 'Размер файла превышает 10 МБ',
    'INVALID_FILE_TYPE' => 'Поддерживаются JPEG, PNG и WebP',
    'TOO_MANY_PHOTOS' => 'Достигнут лимит фотографий',
    _ => message,
  };
}
