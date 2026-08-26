import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<AuthUser?> signIn({
    required String email,
    required String password,
  });

  Future<AuthUser?> register({
    required String email,
    required String password,
  });

  /// Inicia sesión con la cuenta de Google del dispositivo.
  ///
  /// Lanza [AuthFailure] con código 'google-cancelled' si el usuario cierra
  /// el selector de cuentas sin elegir ninguna.
  Future<AuthUser?> signInWithGoogle();

  Future<void> signOut();

  /// Envía un correo de restablecimiento de contraseña a [email].
  Future<void> sendPasswordResetEmail(String email);
}
