import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Obtener el email del usuario actual de forma segura
  String? get currentUserEmail => _auth.currentUser?.email;

  // Stream para detectar cambios de sesión (login/logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint("Error en Login: $e");
      return null;
    }
  }

  // Registrarse con email y contraseña
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint("Error en Registro: $e");
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Verificar si el usuario actual es un colaborador y obtener el email del dueño
  Future<String?> getOwnerForCollaborator(String collaboratorEmail) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('collaborators')
          .where('collaboratorEmail', isEqualTo: collaboratorEmail)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('ownerEmail') as String?;
      }
      return null;
    } catch (e) {
      debugPrint("Error al buscar colaborador: $e");
      return null;
    }
  }
}