import 'package:flutter/material.dart';

/// Opción de un menú de acción desplegable.
class ActionSheetOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Color del texto y el icono. Por defecto usa el tono azulGris del menú.
  final Color color;

  const ActionSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF52606D),
  });
}

/// Menú de acción desplegable con el mismo diseño y animación que el popup de
/// exportar PDF/Imagen: botones tipo FAB extendidos (pill redondeado con icono
/// y texto) que se despliegan hacia abajo con un efecto de fundido y desliz.
///
/// Se usa desde los long press de categorías, subcategorías y productos.
class ActionSheetMenu {
  ActionSheetMenu._();

  static Future<void> show(
    BuildContext context, {
    required List<ActionSheetOption> options,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      elevation: 0,
      builder: (context) => ActionSheetMenuOptions(options: options),
    );
  }
}

/// Columna de botones del menú de acción con la animación de abanico. Envuelve
/// un [ShowModalBottomSheet] con el diseño y animación del popup de exportar.
/// Se usa directamente cuando el menú necesita devolver un valor al cerrarse
/// (p. ej. la acción elegida para una subcategoría).
class ActionSheetMenuOptions extends StatelessWidget {
  final List<ActionSheetOption> options;

  const ActionSheetMenuOptions({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final buttons = <Widget>[];
    for (var i = 0; i < options.length; i++) {
      final option = options[i];
      buttons.add(
        _FanOption(
          delay: Duration(milliseconds: 60 * i),
          dropDown: true,
          child: FloatingActionButton.extended(
            heroTag: 'action_${options.length}_$i',
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : Colors.white,
            foregroundColor: option.color,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: isDark
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.12))
                  : BorderSide.none,
            ),
            onPressed: option.onTap,
            icon: Icon(option.icon, size: 22),
            label: Text(
              option.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
                color: option.color,
              ),
            ),
          ),
        ),
      );
      if (i < options.length - 1) buttons.add(const SizedBox(height: 8));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons,
        ),
      ),
    );
  }
}

class _FanOption extends StatefulWidget {
  const _FanOption({
    required this.delay,
    required this.child,
    this.dropDown = false,
  });

  final Duration delay;
  final Widget child;

  /// Cuando es true los botones se deslizan hacia abajo (menú desplegable);
  /// si no, hacia arriba (abanico de FABs).
  final bool dropDown;

  @override
  State<_FanOption> createState() => _FanOptionState();
}

class _FanOptionState extends State<_FanOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 0,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.dropDown ? -0.6 : 0.6),
      end: Offset.zero,
    ).animate(curved);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
