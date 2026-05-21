class ServerException implements Exception {
  final String message;
  final String? code;
  ServerException(this.message, {this.code});
  
  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
  
  @override
  String toString() => 'CacheException: $message';
}
