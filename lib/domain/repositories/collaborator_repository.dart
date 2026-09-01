import '../entities/access_context.dart';
import '../entities/collaborator.dart';
import '../entities/premium_status.dart';

abstract class CollaboratorRepository {
  /// Resuelve (y cachea por sesión) el contexto de acceso del usuario actual:
  /// de quién son los datos y con qué rol. Devuelve null si no hay sesión.
  Future<AccessContext?> resolveMyAccess();

  Future<void> inviteCollaborator({
    required String ownerEmail,
    required String collaboratorEmail,
    required String role,
  });

  Stream<List<Collaborator>> watchCollaborators(String ownerEmail);

  /// Cuenta (lectura única) los colaboradores activos de un owner.
  Future<int> countCollaborators(String ownerEmail);

  Future<void> updateRole({
    required String docId,
    required String ownerEmail,
    required String collaboratorEmail,
    required String role,
  });

  /// Revoca el acceso del colaborador eliminando su documento.
  Future<void> removeCollaborator({
    required String docId,
    required String collaboratorEmail,
  });

  /// Propaga el plan del owner a todos sus colaboradores: el colaborador
  /// hereda el mismo nivel (premium normal o premium plus) del owner.
  Future<void> syncOwnerTier({required AppTier tier});

  /// Devuelve el contexto de acceso cacheado (null si aún no se ha resuelto).
  AccessContext? get currentAccess;

  /// Invalida el cache de acceso para forzar re-lectura de Firestore.
  void invalidateAccessCache();
}
