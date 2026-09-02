import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/subcategory_item.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/toggle_product.dart';
import '../../domain/usecases/update_product.dart';
import '../localization/app_localizations.dart';
import '../screens/category_detail_screen.dart';
import '../services/subcategory_actions.dart';
import 'action_sheet_menu.dart';
import 'category_visuals.dart';
import 'dialog_kit.dart';
import 'premium_limits.dart';
import 'product_move_animation.dart';
import 'product_visuals.dart';
import 'show_failure.dart';

/// Tarjeta de categoría en la vista lista.
///
/// Es un acordeón controlado por el padre: la tarjeta solo notifica qué quiere
/// expandir (la categoría o una subcategoría) y el padre decide el estado. Así
/// el botón "+" puede adaptarse al contexto (categoría → subcategoría →
/// producto).
class ExpandableCategoryCard extends StatefulWidget {
  final CategoryItem catItem;
  final String localizedCategoryName;
  final List<Product> catProducts;
  final bool isBuyScreen;
  final AppLocalizations t;

  /// Subcategorías persistidas de esta categoría (incluyen las que aún no
  /// tienen productos, con su emoji/foto).
  final List<SubcategoryItem> subcategories;

  /// Si la tarjeta está expandida (nombre de subcategoría expandida o null).
  final bool isExpanded;

  /// Subcategoría expandida dentro de la tarjeta:
  /// - null = ninguna expandida
  /// - '' = "Sin subcategoría" expandida
  /// - 'Nombre' = esa subcategoría expandida
  final String? expandedSubcategory;

  final ValueChanged<bool> onToggleExpanded;
  final ValueChanged<String?> onToggleSubcategory;
  final VoidCallback onCardTap;
  final VoidCallback onLongPressCard;
  final Function(BuildContext, Product) onEditProduct;

  const ExpandableCategoryCard({
    super.key,
    required this.catItem,
    required this.localizedCategoryName,
    required this.catProducts,
    required this.isBuyScreen,
    required this.t,
    required this.subcategories,
    required this.isExpanded,
    required this.expandedSubcategory,
    required this.onToggleExpanded,
    required this.onToggleSubcategory,
    required this.onCardTap,
    required this.onLongPressCard,
    required this.onEditProduct,
  });

  @override
  State<ExpandableCategoryCard> createState() => _ExpandableCategoryCardState();
}

class _ExpandableCategoryCardState extends State<ExpandableCategoryCard> {
  final Map<String, GlobalKey> _productRowKeys = {};

  /// Modo selección múltiple dentro de esta tarjeta: elige varios productos y
  /// los mueve juntos a una subcategoría o categoría.
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  GlobalKey _rowKeyFor(Product product) =>
      _productRowKeys.putIfAbsent(product.uniqueKey, () => GlobalKey());

  void _showProductOptionsBottomSheet(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    ActionSheetMenu.show(
      context,
      options: [
        ActionSheetOption(
          icon: Icons.checklist_rtl,
          label: t.select,
          color: const Color(0xFF0E7490),
          onTap: () {
            Navigator.pop(context);
            _startSelection(product);
          },
        ),
        ActionSheetOption(
          icon: Icons.edit,
          label: '${t.edit} "${t.getProductName(product.nameKey)}"',
          color: const Color(0xFF52606D),
          onTap: () {
            Navigator.pop(context);
            widget.onEditProduct(context, product);
          },
        ),
        ActionSheetOption(
          icon: Icons.drive_file_move_outline,
          label: t.moveProduct,
          color: const Color(0xFF184878),
          onTap: () {
            Navigator.pop(context);
            SubcategoryActions.promptMoveProduct(
              this.context,
              product: product,
              categoryKey: widget.catItem.key,
              subcategories: [for (final s in widget.subcategories) s.name],
              onMoved: () {
                if (mounted) setState(() {});
              },
            );
          },
        ),
        ActionSheetOption(
          icon: Icons.drive_file_move_rtl_outlined,
          label: t.moveToCategory,
          color: const Color(0xFFE8830C),
          onTap: () {
            Navigator.pop(context);
            SubcategoryActions.promptMoveProductToCategory(
              this.context,
              product: product,
              currentCategoryKey: widget.catItem.key,
              onMoved: () {
                if (mounted) setState(() {});
              },
            );
          },
        ),
      ],
    );
  }

  // ------------------------ Modo selección múltiple -----------------

  void _startSelection(Product product) {
    setState(() {
      _selectionMode = true;
      _selectedIds..clear()..add(product.uniqueKey);
    });
    HapticFeedback.lightImpact();
  }

  void _toggleSelection(Product product) {
    setState(() {
      if (!_selectedIds.remove(product.uniqueKey)) {
        _selectedIds.add(product.uniqueKey);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  bool _isSelected(Product product) => _selectedIds.contains(product.uniqueKey);

  Future<void> _moveSelected() async {
    if (!PremiumLimits.checkCanEdit(context)) return;
    final selected = widget.catProducts
        .where((p) => _selectedIds.contains(p.uniqueKey))
        .toList();
    if (selected.isEmpty) return;
    await SubcategoryActions.promptMoveMany(
      this.context,
      products: selected,
      categoryKey: widget.catItem.key,
      subcategories: [for (final s in widget.subcategories) s.name],
      onMoved: () {
        if (mounted) setState(() {});
        _cancelSelection();
      },
    );
  }

  Widget _selectionBar(BuildContext context) {
    final t = widget.t;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);
    return Material(
      color: dark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                t.selectedCount(_selectedIds.length),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: dark ? Colors.grey.shade100 : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: _cancelSelection,
              icon: const Icon(Icons.close),
              label: Text(t.cancel),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: _selectedIds.isEmpty ? null : _moveSelected,
              icon: const Icon(Icons.drive_file_move_outlined, size: 18),
              label: Text(t.move),
              style: FilledButton.styleFrom(backgroundColor: accent),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasProducts = widget.catProducts.isNotEmpty;
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: dark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.62),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.8),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onCardTap,
        onLongPress: widget.onLongPressCard,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'category-circle-${widget.catItem.key}',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.10),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CategoryVisuals.circleChild(
                          categoryKey: widget.catItem.key,
                          imagePath: widget.catItem.imagePath,
                          emoji: widget.catItem.emoji,
                          emojiSize: 45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.localizedCategoryName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: dark
                                ? Colors.grey.shade100
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: hasProducts
                                ? accent.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.catProducts.length} ${widget.t.productsCount}',
                            style: TextStyle(
                              color: hasProducts
                                  ? accent
                                  : (dark ? Colors.grey.shade500 : Colors.grey),
                              fontSize: 12,
                              fontWeight: hasProducts
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: dark ? Colors.grey.shade400 : Colors.grey,
                    ),
                    onPressed: () =>
                        widget.onToggleExpanded(!widget.isExpanded),
                  ),
                ],
              ),
              if (widget.isExpanded) ...[
                const Divider(height: 16),
                ..._expandedChildren(context),
                if (_selectionMode) ...[
                  const SizedBox(height: 8),
                  _selectionBar(context),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Contenido expandido: si hay subcategorías (Premium Plus) se muestran como
  /// filas plegables con su contador; cada fila expandida muestra sus productos.
  /// Sin subcategorías, se muestran los productos directamente.
  List<Widget> _expandedChildren(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (widget.catProducts.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.t.noProducts,
            style: TextStyle(
              color: dark ? Colors.grey.shade500 : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ];
    }

    final plus = PremiumLimits.isPremiumPlusEffectiveSync;
    final subs = SubcategoryActions.visibleSubs(widget.catProducts);
    if (!plus || subs.isEmpty) {
      final children = <Widget>[];
      var index = 0;
      for (final p in widget.catProducts) {
        children.add(_productTile(context, p, index++));
      }
      return children;
    }

    final children = <Widget>[];
    var index = 0;
    void tile(Product p) => children.add(_productTile(context, p, index++));

    for (final sub in subs) {
      final items = widget.catProducts
          .where((p) => SubcategoryActions.subOf(p) == sub)
          .toList();
      final isOpen = widget.expandedSubcategory == sub;
      children.add(_subcategoryRow(context, sub, items.length, isOpen));
      if (isOpen) items.forEach(tile);
    }
    // Los productos sin subcategoría se muestran directamente, mezclados
    // con las filas de subcategorías (sin carpeta "Sin subcategoría").
    SubcategoryActions.ungrouped(widget.catProducts).forEach(tile);
    return children;
  }

  Widget _subcategoryRow(
    BuildContext context,
    String? sub,
    int count,
    bool isOpen,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);
    final label = sub ?? widget.t.noSubcategory;
    final item = sub == null
        ? null
        : SubcategoryActions.itemNamed(widget.subcategories, sub);
    final defaultsToFolder = item == null || item.imagePath == null;
    final hasItems = count > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.62),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: sub == null
              ? () => widget.onToggleSubcategory(isOpen ? null : '')
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryDetailScreen(
                        category: widget.catItem,
                        isBuyScreen: widget.isBuyScreen,
                        subcategoryName: sub,
                        subcategoryItem: item,
                      ),
                    ),
                  );
                },
          onLongPress: sub == null
              ? null
              : () => SubcategoryActions.showMenu(
                  context,
                  categoryKey: widget.catItem.key,
                  sub: sub,
                  accent: accent,
                  onRenamed: () => setState(() {}),
                  onDeleted: () => setState(() {}),
                ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Hero(
                  tag:
                      'subcategory-circle-${widget.catItem.key}-${(sub ?? '').toLowerCase()}',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.10),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: defaultsToFolder
                          ? Center(
                              child: Icon(
                                sub == null
                                    ? Icons.inbox_outlined
                                    : Icons.folder_open_rounded,
                                size: 26,
                                color: accent,
                              ),
                            )
                          : ProductVisuals.circleChild(
                              imagePath: item.imagePath,
                              emoji: null,
                              emojiSize: 28,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: dark
                              ? Colors.grey.shade200
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: hasItems
                              ? accent.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count ${widget.t.productsCount}',
                          style: TextStyle(
                            color: hasItems
                                ? accent
                                : (dark ? Colors.grey.shade500 : Colors.grey),
                            fontSize: 12,
                            fontWeight: hasItems
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: dark ? Colors.grey.shade400 : Colors.grey,
                  ),
                  onPressed: () =>
                      widget.onToggleSubcategory(isOpen ? null : (sub ?? '')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Abre el diálogo de cantidad y unidad (misma lógica que el detalle de
  /// categoría): un solo toque abre ambas opciones y se guardan juntas.
  Future<void> _showQtyUnitDialog(BuildContext context, Product product) async {
    if (!await PremiumLimits.canUseQuantityFeature(context)) return;
    if (!mounted) return;
    final t = widget.t;
    double? qty = product.quantity;
    String? unit = product.unit;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            t.getProductName(product.nameKey),
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                controller: TextEditingController(
                  text: qty != null ? DialogKit.formatQuantity(qty!) : '',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.quantityLabel,
                  hintText: 'Ej: 2',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) => qty = double.tryParse(val),
              ),
              const SizedBox(height: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: unit,
                  isDense: true,
                  isExpanded: true,
                  hint: Text(t.unitLabel),
                  items: DialogKit.unitOptions.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => unit = val),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await sl<UpdateProductUseCase>()(
                      product: product,
                      newName: product.nameKey,
                      emoji: product.emoji,
                      imagePath: product.imagePath,
                      quantity: qty,
                      unit: qty != null ? unit : null,
                    );
                    if (mounted) setState(() {});
                    if (qty != null && mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cantidad: ${DialogKit.formatQuantity(qty!)}${unit != null ? ' $unit' : ''}',
                        ),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } on Failure catch (_) {}
              },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productTile(BuildContext context, Product product, int pIndex) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);

    return Dismissible(
      key: Key('product_${product.uniqueKey}_$pIndex'),
      background: Container(
        color: const Color(0xFF059669),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.swap_horiz, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: const Color(0xFFE11D48),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (_selectionMode) return false;
        if (direction == DismissDirection.startToEnd) {
          if (!PremiumLimits.checkCanMove(context)) return false;
          final rowRect = rectOfContext(
            _productRowKeys[product.uniqueKey]?.currentContext,
          );
          try {
            await sl<ToggleProductUseCase>()(product);
            HapticFeedback.lightImpact();
            if (context.mounted) {
              playProductMove(
                context,
                fromRect: rowRect,
                target: widget.isBuyScreen
                    ? ProductMoveTarget.pantry
                    : ProductMoveTarget.cart,
                preview: buildMovePreview(
                  imagePath: product.imagePath,
                  emoji: product.emoji,
                ),
              );
            }
            return true;
          } on Failure catch (failure) {
            if (context.mounted) showFailure(context, failure);
            return false;
          }
        } else {
          if (!PremiumLimits.checkCanEdit(context)) return false;
          bool? delete = await showDialog<bool>(
            context: context,
            builder: (ctx) => DialogKit.frame(
              ctx,
              title: Text(widget.t.delete),
              content: Text(
                widget.t.deleteProductConfirm(
                  widget.t.getProductName(product.nameKey),
                ),
              ),
              actions: [
                DialogKit.cancelButton(ctx, widget.t.cancel),
                DialogKit.saveButton(
                  ctx,
                  widget.t.delete,
                  DialogAccents.rose,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          );
          if (delete == true) {
            try {
              await sl<DeleteProductUseCase>()(product);
              HapticFeedback.mediumImpact();
              return true;
            } on Failure catch (failure) {
              if (context.mounted) showFailure(context, failure);
              return false;
            }
          }
          return false;
        }
      },
      child: KeyedSubtree(
        key: _rowKeyFor(product),
        child: Container(
          decoration: BoxDecoration(
            color: _isSelected(product)
                ? const Color(0xFF0E7490).withValues(alpha: 0.10)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: _isSelected(product)
                ? Border.all(color: const Color(0xFF0E7490), width: 2)
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (!PremiumLimits.checkCanEdit(context)) return;
              if (_selectionMode) {
                _toggleSelection(product);
                return;
              }
              _showQtyUnitDialog(context, product);
            },
            onLongPress: () {
              if (!PremiumLimits.checkCanEdit(context)) return;
              if (_selectionMode) {
                _toggleSelection(product);
                return;
              }
              _showProductOptionsBottomSheet(context, product);
            },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: ProductVisuals.circleChild(
                      imagePath: product.imagePath,
                      emoji: product.emoji,
                      emojiSize: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.t.getProductName(product.nameKey),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: dark
                          ? Colors.grey.shade200
                          : const Color(0xFF334155),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (product.quantity != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      '${DialogKit.formatQuantity(product.quantity!)}${product.unit != null ? ' ${product.unit}' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
