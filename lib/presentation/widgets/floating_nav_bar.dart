import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import 'floating_nav_spec.dart';

/// Barra inferior flotante en forma de píldora con las dos secciones
/// (Comprar y Despensa). Flota sobre el contenido: el `Scaffold` que la
/// contiene usa `extendBody` para que las listas pasen por debajo.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.buyCount,
    required this.stockCount,
    this.shake,
    required this.onBuyTap,
    required this.onStockTap,
  });

  /// 0 = pantalla de Comprar, 1 = pantalla de Despensa.
  final int currentIndex;
  final int buyCount;
  final int stockCount;

  /// Animación de la sacudida del contador de compras (opcional). En las
  /// pantallas secundarias se pasa null: el badge no se sacude.
  final Animation<double>? shake;

  final VoidCallback onBuyTap;
  final VoidCallback onStockTap;

  static const _rose = Color(0xFFE11D48);
  static const _emerald = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        FloatingNavSpec.sideGap,
        0,
        FloatingNavSpec.sideGap,
        FloatingNavSpec.bottomGap,
      ),
      // Align con heightFactor 1.0 centra la píldora en horizontal sin
      // estirarla en vertical: `Center` llenaría todo el alto disponible del
      // slot de bottomNavigationBar y la barra flotaría en medio de la
      // pantalla (y taparía el contenido).
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: Container(
          height: FloatingNavSpec.height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.86)
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(FloatingNavSpec.height / 2),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.blueGrey.shade900)
                    .withValues(alpha: isDark ? 0.45 : 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navItem(
                context: context,
                selected: currentIndex == 0,
                accent: _rose,
                icon: currentIndex == 0
                    ? Icons.shopping_cart
                    : Icons.shopping_cart_outlined,
                label: t.navBuy,
                badge: buyCount,
                shake: shake,
                onTap: onBuyTap,
              ),
              const SizedBox(width: 26),
              _navItem(
                context: context,
                selected: currentIndex == 1,
                accent: _emerald,
                icon: currentIndex == 1
                    ? Icons.home_rounded
                    : Icons.home_outlined,
                label: t.navStock,
                badge: stockCount,
                shake: null,
                onTap: onStockTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required bool selected,
    required Color accent,
    required IconData icon,
    required String label,
    required int badge,
    required Animation<double>? shake,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = Colors.blueGrey.shade400;

    return InkWell(
      borderRadius: BorderRadius.circular(FloatingNavSpec.height / 2),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.14)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: selected ? accent : muted),
              ),
              if (badge > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: _badge(context, count: badge, accent: accent, shake: shake),
                ),
            ],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? accent
                  : (isDark ? Colors.grey.shade400 : Colors.blueGrey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, {
    required int count,
    required Color accent,
    required Animation<double>? shake,
  }) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(9),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          height: 1.4,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
    if (shake == null) return badge;
    return AnimatedBuilder(
      animation: shake,
      builder: (context, child) {
        // Oscilación horizontal durante la duración de la animación.
        final angle = shake.value * 6 * 2 * math.pi;
        return Transform.translate(
          offset: Offset(math.sin(angle) * 4, 0),
          child: child,
        );
      },
      child: badge,
    );
  }
}

/// Posición del FAB de crear: sobre la posición estándar `endFloat`, se
/// eleva para que no quede tapado por la barra inferior flotante.
class FloatingFabLocation extends FloatingActionButtonLocation {
  const FloatingFabLocation(this.lift);

  final double lift;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final base = FloatingActionButtonLocation.endFloat
        .getOffset(scaffoldGeometry);
    return Offset(base.dx, base.dy - lift);
  }
}