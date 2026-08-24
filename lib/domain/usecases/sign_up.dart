import '../../core/failures.dart';
import '../repositories/auth_repository.dart';

/// Registra una cuenta nueva con email y contraseña.
class SignUpUseCase {
  SignUpUseCase(this._auth);

  final AuthRepository _auth;

  Future<void> call({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw const ValidationFailure('Rellena todos los campos');
    }
    if (password.length < 6) {
      throw const ValidationFailure(
        'La contraseña debe tener al menos 6 caracteres',
      );
    }
    await _auth.register(email: email, password: password);
  }
}
