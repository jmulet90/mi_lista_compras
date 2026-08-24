import '../../core/failures.dart';
import '../repositories/collaborator_repository.dart';

/// Verifica los permisos del usuario actual antes de ejecutar un caso de uso.
class AccessGuard {
  AccessGuard(this._collaborators);

  final CollaboratorRepository _collaborators;

  Future<void> ensureCanMoveItems() => _check(fullEdit: false);

  Future<void> ensureCanFullyEdit() => _check(fullEdit: true);

  Future<void> _check({required bool fullEdit}) async {
    final access = await _collaborators.resolveMyAccess();
    if (access == null || access.isOwner) return;

    if (!access.canMoveItems) {
      throw const PermissionFailure('Tu acceso es de solo lectura');
    }
    if (fullEdit && !access.canFullyEdit) {
      throw const PermissionFailure(
          'Esta acción requiere permiso de Control Total');
    }
  }
}
