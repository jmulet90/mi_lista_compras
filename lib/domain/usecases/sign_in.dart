import '../../core/failures.dart';
import '../repositories/auth_repository.dart';

/// Inicia sesión con email y contraseña ya existentes.
class SignInUseCase {
  SignInUseCase(this._auth);

  final AuthRepository _auth;

  Future<void> call({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw const ValidationFailure('Rellena todos los campos');
    }
    final user = await _auth.signIn(email: email, password: password);
    if (user == null) {
      throw const AuthFailure(
        'Verifica el correo o usa una contraseña de al menos 6 caracteres',
        'unknown',
      );
    }
  }
}
