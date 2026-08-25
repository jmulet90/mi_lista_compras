/// Contexto de acceso del usuario autenticado sobre los datos.
///
/// [role] es null cuando el usuario es el dueño de los datos.
class AccessContext {
  const AccessContext({
    required this.ownerEmail,
    this.role,
    this.ownerPremium = false,
  });

  final String ownerEmail;

  /// `full`, `dynamic` o `read` para colaboradores; null para el dueño.
  final String? role;

  /// true si el owner tiene premium (escrito en el doc del colaborador).
  final bool ownerPremium;

  bool get isOwner => role == null;

  /// Dueño, Control Total y Modo Dinámico pueden mover ítems entre listas.
  bool get canMoveItems => isOwner || role == 'full' || role == 'dynamic';

  /// Solo el dueño y Control Total pueden crear/editar/eliminar.
  bool get canFullyEdit => isOwner || role == 'full';
}
