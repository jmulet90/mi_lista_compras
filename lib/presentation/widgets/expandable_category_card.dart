import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/toggle_product.dart';
import '../../domain/usecases/update_product.dart';
import '../localization/app_localizations.dart';
import 'category_visuals.dart';
import 'dialog_kit.dart';
import 'premium_limits.dart';
import 'product_move_animation.dart';
import 'product_visuals.dart';
import 'show_failure.dart';

class ExpandableCategoryCard extends StatefulWidget {
  final CategoryItem catItem;
  final String localizedCategoryName;
  final List<Product> catProducts;
  final bool isBuyScreen;
  final AppLocalizations t;
  final VoidCallback onTapCard;
  final VoidCallback onLongPressCard;
  final Function(BuildContext, Product) onEditProduct;
  final Function(BuildContext, Product) onDeleteProduct;

  const ExpandableCategoryCard({
    super.key,
    required this.catItem,
    required this.localizedCategoryName,
    required this.catProducts,
    required this.isBuyScreen,
    required this.t,
    required this.onTapCard,
    required this.onLongPressCard,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  @override
  State<ExpandableCategoryCard> createState() => _ExpandableCategoryCardState();
}

class _ExpandableCategoryCardState extends State<ExpandableCategoryCard> {
  bool _isExpanded = false;
  final Map<String, GlobalKey> _productRowKeys = {};

  GlobalKey _rowKeyFor(Product product) =>
      _productRowKeys.putIfAbsent(product.uniqueKey, () => GlobalKey());

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
        onTap: widget.onTapCard,
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
                            color: dark ? Colors.grey.shade100 : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                              fontWeight: hasProducts ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: dark ? Colors.grey.shade400 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const Divider(height: 16),
                if (widget.catProducts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.t.noProducts,
                      style: TextStyle(
                        color: dark ? Colors.grey.shade500 : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.catProducts.length,
                    itemBuilder: (context, pIndex) {
                      final product = widget.catProducts[pIndex];
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
                          if (direction == DismissDirection.startToEnd) {
                            if (!PremiumLimits.checkCanMove(context)) return false;
                            final rowRect =
                                rectOfContext(_productRowKeys[product.uniqueKey]?.currentContext);
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
                                    emoji: product.emoji ?? (widget.isBuyScreen ? '🛒' : '📦'),
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
                                content: Text(widget.t
                                    .deleteProductConfirm(widget.t.getProductName(product.nameKey))),
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
                          child: InkWell(
                            onLongPress: () {
                              if (!PremiumLimits.checkCanEdit(context)) return;
                              widget.onEditProduct(context, product);
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
                                        fallbackEmoji: widget.isBuyScreen ? '🛒' : '📦',
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
                                        color: dark ? Colors.grey.shade200 : const Color(0xFF334155),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _InlineQtyUnit(
                                    product: product,
                                    isBuyScreen: widget.isBuyScreen,
                                    accent: accent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineQtyUnit extends StatefulWidget {
  final Product product;
  final bool isBuyScreen;
  final Color accent;

  const _InlineQtyUnit({
    required this.product,
    required this.isBuyScreen,
    required this.accent,
  });

  @override
  State<_InlineQtyUnit> createState() => _InlineQtyUnitState();
}

class _InlineQtyUnitState extends State<_InlineQtyUnit> {
  late double? _qty;
  late String? _unit;

  @override
  void initState() {
    super.initState();
    _qty = widget.product.quantity;
    _unit = widget.product.unit;
  }

  @override
  void didUpdateWidget(covariant _InlineQtyUnit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.quantity != widget.product.quantity) _qty = widget.product.quantity;
    if (oldWidget.product.unit != widget.product.unit) _unit = widget.product.unit;
  }

  Future<void> _update({double? qty, String? unit}) async {
    setState(() {
      _qty = qty;
      _unit = unit;
    });
    try {
      await sl<UpdateProductUseCase>()(
        product: widget.product,
        newName: widget.product.nameKey,
        emoji: widget.product.emoji,
        imagePath: widget.product.imagePath,
        quantity: qty,
        unit: unit,
      );
    } on Failure catch (_) {}
  }

  void _showQtyInput() async {
    if (!await PremiumLimits.canUseQuantityFeature(context)) return;
    if (!mounted) return;
    final ctrl = TextEditingController(text: _qty != null ? DialogKit.formatQuantity(_qty!) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cantidad', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Ej: 2',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              _update(qty: val, unit: _unit);
              Navigator.pop(ctx);
              if (val != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cantidad: ${DialogKit.formatQuantity(val)}'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUnitPicker() async {
    if (!await PremiumLimits.canUseQuantityFeature(context)) return;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Unidad', style: TextStyle(fontSize: 16)),
        children: DialogKit.unitOptions.map((u) {
          final selected = u == _unit;
          return SimpleDialogOption(
            onPressed: () {
              _update(qty: _qty, unit: u);
              Navigator.pop(ctx);
            },
            child: Text(
              u,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? widget.accent : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textSub = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final showQty = _qty != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _showQtyInput,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.accent.withValues(alpha: 0.25)),
            ),
            child: showQty
                ? Text(
                    DialogKit.formatQuantity(_qty!),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSub),
                  )
                : Icon(Icons.add, size: 16, color: widget.accent),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _showUnitPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.accent.withValues(alpha: 0.25)),
            ),
            child: Text(
              _unit ?? 'un',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSub),
            ),
          ),
        ),
      ],
    );
  }
}
