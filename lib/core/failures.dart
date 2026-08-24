sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de almacenamiento local']);
}

class CloudFailure extends Failure {
  const CloudFailure([super.message = 'Error de sincronización con la nube']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Error de autenticación', this.code]);

  /// Código original (FirebaseAuthException.code o uno propio como
  /// 'google-cancelled') para que la UI muestre el mensaje localizado.
  final String? code;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
