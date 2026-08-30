/// Geometría compartida de la barra inferior flotante. La pantalla principal
/// la dibuja y el contenido (FAB de crear) la usa para saber cuánto debe
/// subir y no quedar escondido detrás de la píldora.
class FloatingNavSpec {
  FloatingNavSpec._();

  static const double height = 60;
  static const double bottomGap = 12;
  static const double sideGap = 16;

  /// Separación que deja el contenido entre la píldora y el FAB.
  static const double contentGap = 16;

  /// Margen inferior estándar del FAB (`endFloat`, equivalente a 16).
  static const double fabMargin = 16;

  /// Cuánto hay que elevar el FAB (respecto a su posición `endFloat`) para
  /// que su borde inferior quede justo encima de la píldora.
  static double fabLift() => height + bottomGap + contentGap - fabMargin;
}