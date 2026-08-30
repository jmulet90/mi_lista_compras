import '../../core/failures.dart';
import '../../domain/entities/access_context.dart';
import '../../domain/entities/collaborator.dart';
import '../../domain/repositories/collaborator_repository.dart';
import '../datasources/collaborator_remote_data_source.dart';

class CollaboratorRepositoryImpl implements CollaboratorRepository {
  CollaboratorRepositoryImpl(this._remote);

  final CollaboratorRemoteDataSource _remote;

  AccessContext? _cachedAccess;
  String? _cachedForEmail;

  @override
  Future<AccessContext?> resolveMyAccess({bool refresh = false}) async {
    final email = _remote.currentUserEmail;
    if (email == null) return null;

    if (!refresh &&
        _cachedForEmail == email &&
        _cachedAccess != null) {
      return _cachedAccess;
    }

      try {
      final data = await _remote.fetchCollaboratorDoc(email);
      if (data == null || (data['ownerEmail'] as String? ?? '').isEmpty) {
        _cachedAccess = AccessContext(ownerEmail: email);
      } else {
        _cachedAccess = AccessContext(
          ownerEmail: data['ownerEmail'] as String,
          role: data['permissionRole'] as String? ?? 'read',
          ownerPremium: data['ownerPremium'] as bool? ?? false,
        );
      }
      _cachedForEmail = email;
      return _cachedAccess;
    } on Failure {
      // Sin red u otro fallo: si ya teníamos contexto se reutiliza.
      if (_cachedForEmail == email && _cachedAccess != null) {
        return _cachedAccess;
      }
      rethrow;
    }
  }

  @override
  Future<void> inviteCollaborator({
    required String ownerEmail,
    required String collaboratorEmail,
    required String role,
  }) async {
    await _remote.inviteCollaborator(CollaboratorInviteData(
      ownerEmail: ownerEmail,
      collaboratorEmail: collaboratorEmail,
      role: role,
    ));
  }

  @override
  Stream<List<Collaborator>> watchCollaborators(String ownerEmail) {
    return _remote.watchCollaborators(ownerEmail).map(
          (snapshot) => snapshot.docs
              .map((d) => _remote.toCollaborator(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<int> countCollaborators(String ownerEmail) async {
    final snapshot = await _remote.watchCollaborators(ownerEmail).first;
    return snapshot.docs.length;
  }

  @override
  Future<void> updateRole({
    required String docId,
    required String ownerEmail,
    required String collaboratorEmail,
    required String role,
  }) async {
    await _remote.updateRole(
      docId: docId,
      ownerEmail: ownerEmail,
      collaboratorEmail: collaboratorEmail,
      role: role,
    );
  }

  @override
  Future<void> removeCollaborator({
    required String docId,
    required String collaboratorEmail,
  }) async {
    await _remote.deleteCollaborator(
      docId: docId,
      collaboratorEmail: collaboratorEmail,
    );
  }

  @override
  AccessContext? get currentAccess => _cachedAccess;

  @override
  void invalidateAccessCache() {
    _cachedAccess = null;
    _cachedForEmail = null;
  }

  @override
  Future<void> syncOwnerPremium({required bool isPremium}) async {
    final email = _remote.currentUserEmail;
    if (email == null) return;
    await _remote.syncOwnerPremium(ownerEmail: email, isPremium: isPremium);
  }
}
