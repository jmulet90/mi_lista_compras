import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/subcategory_item.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/subcategory_repository.dart';
import '../../domain/usecases/update_product.dart';
import '../localization/app_localizations.dart';
import '../widgets/action_sheet_menu.dart';
import '../widgets/dialog_kit.dart';
import '../widgets/show_failure.dart';

/// Acciones reutilizables de subcategorías: agrupación, crear, renombrar y
/// eliminar.
///
/// Una subcategoría tiene dos caras: un [SubcategoryItem] persistido en el
/// [SubcategoryRepository] (para que exista aunque tenga 0 productos, con su
/// visual) y el campo `subcategory` de cada producto (asignación).
/// Renombrar/eliminar actualiza ambos, afectando a los productos de compra y
/// de despensa.
class SubcategoryActions {
  SubcategoryActions._();

  /// Subcategoría efectiva de un producto (null si es "Sin subcategoría").
  static String? subOf(Product p) {
    final s = p.subcategory?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Subcategorías de la categoría: nombres persistidos más los nombres que
  /// aparecen en los productos (para no perder datos heredados), ordenados.
  static List<String> distinct(
    List<Product> products, {
    List<String> known = const [],
  }) {
    final set = <String>{};
    for (final p in products) {
      final sub = subOf(p);
      if (sub != null) set.add(sub);
    }
    for (final name in known) {
      final n = name.trim();
      if (n.isNotEmpty) set.add(n);
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Nombres de subcategorías a mostrar para una categoría en [products]:
  /// solo las que aparecen en esos productos. Una subcategoría vacía no se
  /// muestra hasta que tarda al menos un producto en esa pantalla (compra o
  /// despensa), igual que las heredadas.
  static List<String> visibleSubs(List<Product> products) => distinct(products);

  /// El [SubcategoryItem] persistido cuyo nombre coincide con [name], o null.
  static SubcategoryItem? itemNamed(List<SubcategoryItem> items, String name) {
    final normalized = name.toLowerCase();
    for (final it in items) {
      if (it.name.toLowerCase() == normalized) return it;
    }
    return null;
  }

  /// Productos sin subcategoría de la lista dada.
  static List<Product> ungrouped(List<Product> products) =>
      products.where((p) => subOf(p) == null).toList();

  /// Crea (persiste) una subcategoría con su visual en la categoría.
  static Future<void> create(String categoryKey, SubcategoryItem item) async {
    try {
      await sl<SubcategoryRepository>().create(categoryKey, item);
    } on Failure {
      rethrow;
    } catch (_) {
      throw const CacheFailure();
    }
  }

  /// Diálogo de texto reutilizable (nueva subcategoría / renombrar).
  static Future<String?> promptName(
    BuildContext context, {
    required String title,
    required String label,
    String? hint,
    String? initial,
    required Color accent,
    required String save,
    required String cancel,
  }) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => DialogKit.frame(
        ctx,
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: DialogKit.input(ctx, accent, label: label, hint: hint),
        ),
        actions: [
          DialogKit.cancelButton(ctx, cancel),
          DialogKit.saveButton(
            ctx,
            save,
            accent,
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          ),
        ],
      ),
    );
  }

  /// Renombra una subcategoría en [categoryKey]: actualiza la caja (conservando
  /// su visual) y todos sus productos (compra y despensa).
  static Future<bool> rename(
    BuildContext context, {
    required String categoryKey,
    required String from,
    required String to,
  }) async {
    try {
      final repo = sl<SubcategoryRepository>();
      final items = await repo.itemsFor(categoryKey);
      final old = itemNamed(items, from);
      await repo.rename(
        categoryKey,
        from,
        SubcategoryItem(
          name: to,
          emoji: old?.emoji,
          imagePath: old?.imagePath,
        ),
      );
    } on Failure catch (failure) {
      if (context.mounted) showFailure(context, failure);
      return false;
    }
    return _applyTo(
      context,
      categoryKey: categoryKey,
      matching: from,
      subcategory: to,
    );
  }

  /// Elimina una subcategoría en [categoryKey]: la retira de la caja y sus
  /// productos (compra y despensa) vuelven a "Sin subcategoría".
  static Future<bool> delete(
    BuildContext context, {
    required String categoryKey,
    required String sub,
  }) async {
    try {
      await sl<SubcategoryRepository>().delete(categoryKey, sub);
    } on Failure catch (failure) {
      if (context.mounted) showFailure(context, failure);
      return false;
    }
    return _applyTo(
      context,
      categoryKey: categoryKey,
      matching: sub,
      subcategory: null,
    );
  }

  /// Recupera todos los productos de la categoría con la subcategoría
  /// [matching] y les aplica el nuevo valor. Devuelve false ante cualquier
  /// fallo.
  static Future<bool> _applyTo(
    BuildContext context, {
    required String categoryKey,
    required String matching,
    required String? subcategory,
  }) async {
    List<Product> targets;
    try {
      final all = await sl<ProductRepository>().getAll();
      final normalizedCategory = categoryKey.trim().toLowerCase();
      targets = all
          .where((p) =>
              p.categoryKey.trim().toLowerCase() == normalizedCategory &&
              subOf(p) == matching)
          .toList();
    } on Failure catch (failure) {
      if (context.mounted) showFailure(context, failure);
      return false;
    }
    for (final p in targets) {
      try {
        await sl<UpdateProductUseCase>()(
          product: p,
          newName: p.nameKey,
          emoji: p.emoji,
          imagePath: p.imagePath,
          quantity: p.quantity,
          unit: p.unit,
          subcategory: subcategory,
        );
      } on Failure catch (failure) {
        if (context.mounted) showFailure(context, failure);
        return false;
      }
    }
    return true;
  }

  /// Muestra el menú para mover [product] a otra subcategoría de su categoría
  /// (o a "Sin subcategoría"). Las opciones unen los nombres persistidos con
  /// los que aparecen en los productos, igual que el agrupado.
  static Future<void> promptMoveProduct(
    BuildContext context, {
    required Product product,
    required String categoryKey,
    required List<String> subcategories,
    required VoidCallback onMoved,
  }) async {
    final t = AppLocalizations.of(context);
    final current = subOf(product);
    final normalizedCurrent = current ?? '';
    debugPrint('[MOVE] start current=$current');

    final all = await sl<ProductRepository>().getAll();
    debugPrint('[MOVE] getAll=${all.length}');
    final catProducts = all
        .where((p) =>
            p.categoryKey.trim().toLowerCase() == categoryKey.trim().toLowerCase())
        .toList();
    final options = distinct(catProducts, known: subcategories);
    final targetList = <String>['', ...options];
    debugPrint('[MOVE] options=$targetList');

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${t.moveProduct}: ${t.getProductName(product.nameKey)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              for (final sub in targetList)
                ListTile(
                  leading: Icon(
                    sub.isEmpty ? Icons.inbox_outlined : Icons.folder_open_outlined,
                    color:
                        sub.isEmpty ? Colors.grey : const Color(0xFF184878),
                  ),
                  title: Text(sub.isEmpty ? t.noSubcategory : sub),
                  trailing: sub == normalizedCurrent
                      ? const Icon(Icons.check, size: 18, color: Colors.green)
                      : null,
                  onTap: () {
                    final target = sub;
                    debugPrint('[MOVE] tap tapped=$target');
                    Navigator.of(sheetContext).pop();
                    _performMove(
                      context,
                      product: product,
                      t: t,
                      current: current,
                      chosen: target,
                      onMoved: onMoved,
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _performMove(
    BuildContext context, {
    required Product product,
    required AppLocalizations t,
    required String? current,
    required String chosen,
    required VoidCallback onMoved,
  }) async {
    if (!context.mounted) return;
    final normalizedCurrent = current ?? '';
    if (chosen == normalizedCurrent) return;
    debugPrint('[MOVE] chosen=$chosen normalized=$normalizedCurrent calling update');
    try {
      await sl<UpdateProductUseCase>()(
        product: product,
        newName: product.nameKey,
        emoji: product.emoji,
        imagePath: product.imagePath,
        quantity: product.quantity,
        unit: product.unit,
        subcategory: chosen.isEmpty ? null : chosen,
      );
      debugPrint('[MOVE] update ok');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t.movedProductTo(chosen.isEmpty ? t.noSubcategory : chosen),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        onMoved();
      }
    } on Failure catch (failure) {
      debugPrint('[MOVE] failure ${failure.runtimeType}: $failure');
      if (context.mounted) showFailure(context, failure);
    } catch (e) {
      debugPrint('[MOVE] EXC $e');
    }
  }

  /// Menú de una subcategoría (renombrar / eliminar).
  static Future<void> showMenu(
    BuildContext context, {
    required String categoryKey,
    required String sub,
    required Color accent,
    required VoidCallback onRenamed,
    required VoidCallback onDeleted,
  }) async {
    final t = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      elevation: 0,
      builder: (sheetContext) => ActionSheetMenuOptions(
        options: [
          ActionSheetOption(
            icon: Icons.drive_file_rename_outline,
            label: t.renameSubcategory,
            color: const Color(0xFF52606D),
            onTap: () => Navigator.of(sheetContext).pop('rename'),
          ),
          ActionSheetOption(
            icon: Icons.delete_outline,
            label: t.deleteSubcategory,
            color: const Color(0xFFE11D48),
            onTap: () => Navigator.of(sheetContext).pop('delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;

    if (action == 'rename') {
      final name = await promptName(
        context,
        title: t.renameSubcategory,
        label: t.subcategory,
        initial: sub,
        accent: accent,
        save: t.save,
        cancel: t.cancel,
      );
      if (name == null || name.isEmpty || name == sub || !context.mounted) {
        return;
      }
      final ok = await rename(
        context,
        categoryKey: categoryKey,
        from: sub,
        to: name,
      );
      if (ok && context.mounted) onRenamed();
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => DialogKit.frame(
          ctx,
          title: Text(t.deleteSubcategory),
          content: Text(t.deleteSubcategoryConfirm(sub)),
          actions: [
            DialogKit.cancelButton(ctx, t.cancel),
            DialogKit.saveButton(
              ctx,
              t.delete,
              DialogAccents.rose,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      if (ok == true && context.mounted) {
        final done = await delete(
          context,
          categoryKey: categoryKey,
          sub: sub,
        );
        if (done && context.mounted) onDeleted();
      }
    }
  }
}