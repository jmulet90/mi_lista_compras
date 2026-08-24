import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/toggle_product.dart';
import '../../core/failures.dart';
import '../localization/app_localizations.dart';
import 'category_visuals.dart';
import 'product_move_animation.dart';
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
    final hasProducts = widget.catProducts.isNotEmpty;
    final activeColor = widget.isBuyScreen ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                        color: hasProducts
                            ? activeColor.withValues(alpha: 0.25)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
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
                          widget.localizedCategoryName.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasProducts
                                ? activeColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.catProducts.length} ${widget.t.productsCount}',
                            style: TextStyle(
                              color: hasProducts ? activeColor.shade700 : Colors.grey,
                              fontSize: 12,
                              fontWeight: hasProducts ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey,
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
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.swap_horiz, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
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
                            bool? delete = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(widget.t.delete),
                                content: Text(widget.t
                                    .deleteProductConfirm(widget.t.getProductName(product.nameKey))),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(widget.t.cancel),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(widget.t.delete),
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
                            onLongPress: () => widget.onEditProduct(context, product),
                            child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(shape: BoxShape.circle),
                              child: ClipOval(
                                child: product.imagePath != null
                                    ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                                    : Center(
                                  child: Text(
                                    product.emoji ?? (widget.isBuyScreen ? '🛒' : '📦'),
                                    style: const TextStyle(fontSize: 35),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              widget.t.getProductName(product.nameKey),
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
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
