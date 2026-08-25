import '../entities/access_context.dart';
import '../entities/collaborator.dart';

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

  /// Propaga el estado premium del owner a todos sus colaboradores.
  Future<void> syncOwnerPremium({required bool isPremium});
}
