import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth);

  final FirebaseAuth _auth;
  final GoogleSignIn _google = GoogleSignIn();

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(_toEntity);
  }

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _toEntity(user);
  }

  @override
  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toEntity(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyMessage(e.code), e.code);
    } catch (_) {
      throw const AuthFailure(
        'Error inesperado al iniciar sesión',
        'unknown',
      );
    }
  }

  @override
  Future<AuthUser?> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toEntity(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyMessage(e.code), e.code);
    } catch (_) {
      throw const AuthFailure(
        'Error inesperado al registrar la cuenta',
        'unknown',
      );
    }
  }

  @override
  Future<AuthUser?> signInWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) {
        throw const AuthFailure('Inicio cancelado', 'google-cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return _toEntity(userCredential.user);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyMessage(e.code), e.code);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'No se pudo iniciar sesión con Google',
        'google-error',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_google.currentUser != null) await _google.signOut();
      await _auth.signOut();
    } catch (e) {
      throw const AuthFailure('No se pudo cerrar la sesión');
    }
  }

  String _friendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Contraseña incorrecta';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu red e inténtalo de nuevo';
      default:
        return 'Verifica los datos e inténtalo de nuevo';
    }
  }

  AuthUser? _toEntity(User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email);
  }
}
