class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

class NoConnectionException extends AppException {
  NoConnectionException() : super('No internet connection');
}
