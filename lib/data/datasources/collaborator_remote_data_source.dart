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

  static String docId(String email) =>
      email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

  /// Devuelve el documento de colaborador del email dado, o null si no existe.
  Future<Map<String, dynamic>?> fetchCollaboratorDoc(String email) async {
    try {
      final snapshot = await _db
          .collection('collaborators')
          .doc(docId(email))
          .get();
      return snapshot.data();
    } catch (e) {
      throw CloudFailure('No se pudo verificar el estado de colaborador: $e');
    }
  }

  Future<void> inviteCollaborator(CollaboratorInviteData invite) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Usuario no autenticado');

    await _db
        .collection('collaborators')
        .doc(docId(invite.collaboratorEmail))
        .set({
      'ownerEmail': user.email ?? invite.ownerEmail,
      'collaboratorEmail': invite.collaboratorEmail,
      'permissionRole': invite.role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollaborators(
    String ownerEmail,
  ) {
    return _db
        .collection('collaborators')
        .where('ownerEmail', isEqualTo: ownerEmail)
        .snapshots();
  }

  Future<void> updateRole({
    required String ownerEmail,
    required String collaboratorEmail,
    required String role,
  }) async {
    await _db.collection('collaborators').doc(docId(collaboratorEmail)).update({
      'permissionRole': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Collaborator toCollaborator(Map<String, dynamic> data) {
    return Collaborator(
      email: data['collaboratorEmail'] as String? ?? 'Sin correo',
      role: data['permissionRole'] as String? ?? 'read',
    );
  }
}
