import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/shopping_suggestion_item.dart';
import '../../domain/repositories/notification_center_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/add_product.dart';
import '../localization/app_localizations.dart';
import '../widgets/dialog_kit.dart';
import '../widgets/product_visuals.dart';

/// Línea editable de la sugerencia: qué producto, con qué cantidad/unidad
/// y desde qué producto existente toma su visual.
class _SuggestionLine {
  _SuggestionLine({
    required this.productKey,
    required this.categoryKey,
    this.quantity,
    this.unit,
    this.emoji,
    this.imagePath,
    this.subcategory,
  });

  final String productKey;
  final String categoryKey;
  double? quantity;
  String? unit;
  final String? emoji;
  final String? imagePath;
  final String? subcategory;

  String get key =>
      '${categoryKey.trim().toLowerCase()}_${productKey.trim().toLowerCase()}';
}

/// Muestra los productos "habituales" sugeridos por el análisis de patrones
/// de compra y permite agregarlos de una sola vez a la lista de compras,
/// editando antes las cantidades, quitando productos o añadiendo otros.
class ShoppingSuggestionScreen extends StatefulWidget {
  const ShoppingSuggestionScreen({super.key, required this.notificationId});

  final String notificationId;

  @override
  State<ShoppingSuggestionScreen> createState() => _ShoppingSuggestionScreenState();
}

class _ShoppingSuggestionScreenState extends State<ShoppingSuggestionScreen> {
  AppNotification? _notification;
  bool _loading = true;
  List<_SuggestionLine> _items = [];
  Map<String, Product> _existingByKey = {};
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notification = await sl<NotificationCenterRepository>().getById(widget.notificationId);
    final products = await sl<ProductRepository>().getAll();
    if (!mounted) return;
    setState(() {
      _notification = notification;
      _existingByKey = {
        for (final p in products) '${p.categoryKey}_${p.nameKey.trim().toLowerCase()}': p,
      };
      _items = [
        for (final s in notification?.suggestions ?? const <ShoppingSuggestionItem>[])
          _SuggestionLine(
            productKey: s.productKey,
            categoryKey: s.categoryKey,
            quantity: s.quantity,
            unit: s.unit,
            emoji: _existingFor(s.productKey, s.categoryKey)?.emoji,
            imagePath: _existingFor(s.productKey, s.categoryKey)?.imagePath,
            subcategory: _existingFor(s.productKey, s.categoryKey)?.subcategory,
          ),
      ];
      _loading = false;
    });
  }

  Product? _existingFor(String productKey, String categoryKey) =>
      _existingByKey['${categoryKey}_${productKey.trim().toLowerCase()}'];

  Future<void> _editLine(_SuggestionLine line) async {
    var quantity = line.quantity;
    var unit = line.unit;
    final t = AppLocalizations.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DialogKit.frame(
        dialogContext,
        title: Text(t.getProductName(line.productKey)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DialogKit.quantityUnitRow(
                context: dialogContext,
                accent: DialogAccents.emerald,
                quantity: quantity,
                unit: unit,
                onQuantityChanged: (val) {
                  setDialogState(() => quantity = val);
                },
                onUnitChanged: (val) {
                  setDialogState(() => unit = val);
                },
              ),
              if (quantity == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    t.suggestionQuantityEmpty,
                    style: TextStyle(
                      fontSize: 12,
                      color: DialogKit.isDark(dialogContext)
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          DialogKit.cancelButton(dialogContext, t.cancel),
          DialogKit.saveButton(dialogContext, t.save, DialogAccents.emerald,
              onPressed: () => Navigator.pop(dialogContext, true)),
        ],
      ),
    );
    if (saved == true) {
      setState(() {
        line.quantity = quantity;
        line.unit = unit;
      });
    }
  }

  Future<void> _pickMore() async {
    final t = AppLocalizations.of(context);
    final products = _existingByKey.values.toList()
      ..sort((a, b) {
        final byName = a.nameKey.toLowerCase().compareTo(b.nameKey.toLowerCase());
        if (byName != 0) return byName;
        return a.categoryKey.compareTo(b.categoryKey);
      });
    final already = _items.map((i) => i.key).toSet();
    String keyOf(Product p) =>
        '${p.categoryKey.trim().toLowerCase()}_${p.nameKey.trim().toLowerCase()}';
    final picked = <String>{};
    final searchController = TextEditingController();

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        String query = '';
        return AlertDialog(
          backgroundColor: DialogKit.isDark(dialogContext)
              ? const Color(0xFF1E293B)
              : Colors.white.withValues(alpha: 0.97),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            t.suggestionAddMoreItems,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DialogKit.isDark(dialogContext)
                  ? Colors.grey.shade100
                  : DialogAccents.ink,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              final filtered = query.trim().isEmpty
                  ? products
                  : products
                      .where((p) => t
                          .getProductName(p.nameKey)
                          .toLowerCase()
                          .contains(query.trim().toLowerCase()))
                      .toList();
              return SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(dialogContext).size.height * 0.55,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (v) => setDialogState(() => query = v),
                      decoration: DialogKit.input(
                        dialogContext,
                        DialogAccents.emerald,
                        label: t.suggestionSearchHint,
                      ).copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                t.suggestionNoResults,
                                style: TextStyle(
                                  color: DialogKit.isDark(dialogContext)
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final p = filtered[index];
                                final key = keyOf(p);
                                return CheckboxListTile(
                                  value: picked.contains(key),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        picked.add(key);
                                      } else {
                                        picked.remove(key);
                                      }
                                    });
                                  },
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  secondary: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: DialogAccents.emerald
                                          .withValues(alpha: 0.10),
                                    ),
                                    child: ClipOval(
                                      child: ProductVisuals.circleChild(
                                        imagePath: p.imagePath,
                                        emoji: p.emoji,
                                        emojiSize: 30,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    t.getProductName(p.nameKey),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    t.getCategoryName(p.categoryKey),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DialogKit.isDark(dialogContext)
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            DialogKit.cancelButton(dialogContext, t.cancel),
            DialogKit.saveButton(dialogContext, t.save, DialogAccents.emerald,
                onPressed: () => Navigator.pop(dialogContext, picked)),
          ],
        );
      },
    );
    searchController.dispose();
    if (result == null || result.isEmpty) return;
    setState(() {
      for (final key in result) {
        if (already.contains(key)) continue;
        final p = _existingByKey[key];
        if (p == null) continue;
        _items.add(_SuggestionLine(
          productKey: p.nameKey,
          categoryKey: p.categoryKey,
          emoji: p.emoji,
          imagePath: p.imagePath,
          subcategory: p.subcategory,
        ));
      }
    });
  }

  Future<void> _addSelected() async {
    if (_items.isEmpty) return;
    setState(() => _adding = true);
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    try {
      for (final item in _items) {
        final canonical = AppLocalizations.canonicalName(item.productKey)
            .trim()
            .toLowerCase();
        final alreadyExists = _existingByKey.values.any(
          (p) =>
              p.categoryKey == item.categoryKey &&
              AppLocalizations.canonicalName(p.nameKey)
                      .trim()
                      .toLowerCase() ==
                  canonical,
        );
        if (alreadyExists) continue;
        final existing = _existingFor(item.productKey, item.categoryKey);
        await sl<AddProductUseCase>()(
          name: existing?.nameKey ?? item.productKey,
          categoryKey: item.categoryKey,
          isBuyScreen: true,
          emoji: item.emoji ?? existing?.emoji,
          imagePath: item.imagePath ?? existing?.imagePath,
          quantity: item.quantity,
          unit: item.unit,
          subcategory: item.subcategory,
        );
      }
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.suggestionsAddedSuccess)));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(t.suggestedProductsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notification == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      t.noActiveSuggestion,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.suggestedProductsSubtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickMore,
                            icon: const Icon(Icons.add_box_outlined, size: 18),
                            label: Text(
                              t.suggestionAddMoreItems,
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: DialogAccents.emerald,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t.suggestionEditHint,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _items.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  t.notificationCenterEmpty,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                final existing = _existingFor(item.productKey, item.categoryKey);
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: DialogAccents.emerald
                                          .withValues(alpha: 0.10),
                                    ),
                                    child: ClipOval(
                                      child: ProductVisuals.circleChild(
                                        imagePath: item.imagePath ??
                                            existing?.imagePath,
                                        emoji: item.emoji ?? existing?.emoji,
                                        emojiSize: 34,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    t.getProductName(item.productKey),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  subtitle: Text(
                                    item.quantity != null
                                        ? '${DialogKit.formatQuantity(item.quantity!)}${item.unit != null ? ' ${item.unit}' : ''}'
                                        : t.suggestionQuantityEmpty,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: DialogAccents.emerald,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: true,
                                        activeColor: DialogAccents.emerald,
                                        onChanged: (val) {
                                          if (val == false) {
                                            setState(
                                                () => _items.removeAt(index));
                                          }
                                        },
                                      ),
                                      IconButton(
                                        tooltip: t.suggestionEdit,
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 20),
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                        onPressed: () => _editLine(item),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      minimum: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: DialogAccents.emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: (_adding || _items.isEmpty) ? null : _addSelected,
                          icon: _adding
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.add_shopping_cart_rounded),
                          label: Text(t.addSuggestedToList),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}