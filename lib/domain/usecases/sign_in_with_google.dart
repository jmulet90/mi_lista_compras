import '../../core/failures.dart';
import '../repositories/auth_repository.dart';

/// Inicia sesión con la cuenta de Google del dispositivo.
class SignInWithGoogleUseCase {
  SignInWithGoogleUseCase(this._auth);

  final AuthRepository _auth;

  Future<void> call() async {
    try {
      await _auth.signInWithGoogle();
    } on AuthFailure catch (failure) {
      // El cancelo del selector no es un error real: se ignora en silencio.
      if (failure.code != 'google-cancelled') rethrow;
    }
  }
}
