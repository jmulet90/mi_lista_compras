import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/failures.dart';
import '../../domain/entities/collaborator.dart';

class CollaboratorInviteData {
  const CollaboratorInviteData({
    required this.ownerEmail,
    required this.collaboratorEmail,
    required this.role,
  });

  final String ownerEmail;
  final String collaboratorEmail;
  final String role;
}

/// Acceso a Firestore para la gestión de colaboradores.
///
/// La colección raíz `collaborators` es la fuente autoritativa:
/// doc id = email del colaborador sanitizado, campos:
/// ownerEmail, collaboratorEmail, permissionRole, updatedAt.
class CollaboratorRemoteDataSource {
  CollaboratorRemoteDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get currentUserUid => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

  static String docIdOf(String email) =>
      email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

  /// Devuelve el documento de colaborador del email dado, o null si no existe.
  /// Si el ID canónico no existe, busca por email (soporta documentos
  /// creados con esquemas de ID anteriores).
  Future<Map<String, dynamic>?> fetchCollaboratorDoc(String email) async {
    try {
      final snapshot = await _db
          .collection('collaborators')
          .doc(docIdOf(email))
          .get();
      final direct = snapshot.data();
      if (direct != null) return direct;

      final query = await _db
          .collection('collaborators')
          .where('collaboratorEmail', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return query.docs.first.data();

      if (email.toLowerCase() != email) {
        final lower = await _db
            .collection('collaborators')
            .where('collaboratorEmail', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (lower.docs.isNotEmpty) return lower.docs.first.data();
      }
      return null;
    } catch (e) {
      throw CloudFailure('No se pudo verificar el estado de colaborador: $e');
    }
  }

  Future<void> inviteCollaborator(CollaboratorInviteData invite) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Usuario no autenticado');

    try {
      await _db
          .collection('collaborators')
          .doc(docIdOf(invite.collaboratorEmail))
          .set({
        'ownerEmail': user.email ?? invite.ownerEmail,
        'collaboratorEmail': invite.collaboratorEmail,
        'permissionRole': invite.role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw CloudFailure('No se pudo invitar al colaborador: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollaborators(
    String ownerEmail,
  ) {
    return _db
        .collection('collaborators')
        .where('ownerEmail', isEqualTo: ownerEmail)
        .snapshots();
  }

  /// Escribe el rol sobre el documento real (docId) que muestra la lista.
  /// Con set+merge: funciona aunque falten campos y nunca crea duplicados.
  Future<void> updateRole({
    required String docId,
    required String ownerEmail,
    required String collaboratorEmail,
    required String role,
  }) async {
    final effectiveDoc = docId.isNotEmpty ? docId : docIdOf(collaboratorEmail);
    try {
      await _db.collection('collaborators').doc(effectiveDoc).set({
        'ownerEmail': ownerEmail,
        'collaboratorEmail': collaboratorEmail,
        'permissionRole': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw CloudFailure('No se pudo actualizar el permiso: $e');
    }
  }

  Future<void> deleteCollaborator({
    required String docId,
    required String collaboratorEmail,
  }) async {
    final effectiveDoc = docId.isNotEmpty ? docId : docIdOf(collaboratorEmail);
    try {
      await _db.collection('collaborators').doc(effectiveDoc).delete();
    } catch (e) {
      throw CloudFailure('No se pudo eliminar al colaborador: $e');
    }
  }

  Collaborator toCollaborator(String docId, Map<String, dynamic> data) {
    return Collaborator(
      docId: docId,
      email: data['collaboratorEmail'] as String? ?? 'Sin correo',
      role: data['permissionRole'] as String? ?? 'read',
    );
  }
}
