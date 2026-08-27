import 'package:flutter/foundation.dart';

/// Fase de la sesión que decide la pantalla raíz de la app.
///
/// Es una única fuente de verdad: el watcher de auth en `bootstrap.dart` la
/// actualiza a medida que resuelve la sesión, y la app solo reacciona a este
/// notificador (nunca adivina con streams crudos ni con `lastAuthUid`).
enum AppSessionPhase {
  /// Arranque en frío, sin confirmar aún si hay una sesión guardada.
  loading,

  /// Usuario autenticado; se están cargando sus datos antes de mostrar la app.
  authenticatedLoadingData,

  /// Sesión lista: se pueden mostrar los datos de la cuenta en la app.
  ready,

  /// Sin sesión activa (primer uso o tras cerrar sesión): mostrar el login.
  unauthenticated,
}

/// Fuente de verdad del estado de la sesión para toda la app.
class SessionStatusNotifier extends ValueNotifier<AppSessionPhase> {
  SessionStatusNotifier([super.value = AppSessionPhase.loading]);
}