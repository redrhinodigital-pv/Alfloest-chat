/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    if (code != null) return '[$code] $message';
    return message;
  }
}

/// Supabase Database related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

/// Authentication related exceptions
class AppAuthException extends AppException {
  const AppAuthException(super.message, {super.code, super.originalError});
}

/// Storage related exceptions
class AppStorageException extends AppException {
  const AppStorageException(super.message, {super.code, super.originalError});
}

/// Cache related exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.originalError});
}
