import '../../core/failures.dart';
import '../repositories/auth_repository.dart';

/// Envía un correo de restablecimiento de contraseña al email indicado.
class ResetPasswordUseCase {
  ResetPasswordUseCase(this._auth);

  final AuthRepository _auth;

  Future<void> call({required String email}) async {
    if (email.isEmpty) {
      throw const ValidationFailure('Introduce tu correo electrónico');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw const ValidationFailure('El correo no tiene un formato válido');
    }
    await _auth.sendPasswordResetEmail(email);
  }
}
