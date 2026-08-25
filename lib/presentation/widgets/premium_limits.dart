import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/premium_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../localization/app_localizations.dart';
import 'paywall_dialog.dart';

/// Límites de la versión gratuita y comprobaciones reutilizables.
///
/// Modelo "todo visible": la UI premium siempre se muestra; si el usuario
/// free toca una función exclusiva, se abre el paywall y se devuelve false.
class PremiumLimits {
  PremiumLimits._();

  static const int maxFreeCategories = 8;
  static const int maxFreeProductsPerCategory = 15;

  static bool get isPremium => sl<PremiumRepository>().current().isPremium;

  static Future<bool> _gate(
    BuildContext context,
    String? reason,
  ) async {
    if (context.mounted) await showPaywall(context, reason: reason);
    return false;
  }

  /// Verifica si puede crearse una categoría más; si se alcanzó el tope
  /// gratuito muestra el paywall y devuelve false.
  static Future<bool> canAddCategory(BuildContext context) async {
    if (isPremium) return true;
    final t = AppLocalizations.of(context);
    final categories = await sl<CategoryRepository>().getAll();
    if (categories.length < maxFreeCategories) return true;
    if (!context.mounted) return false;
    await showPaywall(context, reason: t.premiumLimitCategories);
    return false;
  }

  /// Verifica si la categoría puede recibir otro producto; si se alcanzó
  /// el tope gratuito muestra el paywall y devuelve false.
  static Future<bool> canAddProduct(
    BuildContext context,
    String categoryKey,
  ) async {
    if (isPremium) return true;
    final t = AppLocalizations.of(context);
    final normalized = categoryKey.trim().toLowerCase();
    final products = await sl<ProductRepository>().getAll();
    final count = products
        .where((p) => p.categoryKey.trim().toLowerCase() == normalized)
        .length;
    if (count < maxFreeProductsPerCategory) return true;
    if (!context.mounted) return false;
    await showPaywall(context, reason: t.premiumLimitProducts);
    return false;
  }

  /// Gestión e invitación de colaboradores (solo premium).
  static Future<bool> canManageCollaborators(BuildContext context) =>
      isPremium ? Future.value(true) : _gate(
        context,
        AppLocalizations.of(context).premiumLimitCollaborators,
      );

  /// Funciones de apariencia exclusivas de premium (modo oscuro, galería).
  static Future<bool> canUseAppearanceFeature(BuildContext context) =>
      isPremium ? Future.value(true) : _gate(
        context,
        AppLocalizations.of(context).premiumFeatureExclusive,
      );

  /// Cantidades y unidades en productos (solo premium).
  static Future<bool> canUseQuantityFeature(BuildContext context) =>
      isPremium ? Future.value(true) : _gate(
        context,
        AppLocalizations.of(context).premiumFeatureExclusive,
      );
}
