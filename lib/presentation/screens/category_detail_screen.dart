import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/toggle_product.dart';
import '../../domain/usecases/update_product.dart';
import '../../domain/repositories/product_repository.dart';
import '../app_settings.dart';
import '../localization/app_localizations.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/category_visuals.dart';
import '../widgets/product_move_animation.dart';
import '../widgets/show_failure.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryItem category;
  final bool isBuyScreen;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.isBuyScreen,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final Map<String, GlobalKey> _productRowKeys = {};

  GlobalKey _rowKeyFor(Product product) =>
      _productRowKeys.putIfAbsent(product.id, () => GlobalKey());

  void _showProductOptionsBottomSheet(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueGrey),
              title: Text('${t.edit} "${t.getProductName(product.nameKey)}"'),
              onTap: () {
                Navigator.pop(context);
                _showEditProductDialog(context, product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('${t.delete} "${t.getProductName(product.nameKey)}"'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteProduct(context, product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    final nameController =
        TextEditingController(text: t.getProductName(product.nameKey));
    String? selectedEmoji = product.emoji ?? '📦';
    String? imagePath = product.imagePath;
    const List<String> emojis = ['🥛', '🍞', '🍎', '🍐', '🍊', '🍋', '🍉', '🍇', '🍓', '🫐', '🍒', '🥭','🍍', '🥥', '🥝', '🥑', '🥩', '☕', '🥐', '🧀', '🍌', '🍅', '🧻', '🧼', '🧊'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(t.edit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(labelText: t.edit),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade700, width: 2),
                      ),
                      child: ClipOval(
                        child: imagePath != null
                            ? Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            : Center(
                          child: Text(
                            selectedEmoji ?? '📦',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(t.visualCustomization, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.maxFinite,
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: emojis.length,
                      itemBuilder: (context, index) {
                        final emoji = emojis[index];
                        final isSelected = (selectedEmoji == emoji) && (imagePath == null);

                        return SizedBox(
                          width: 65,
                          height: 65,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                setDialogState(() {
                                  selectedEmoji = emoji;
                                  imagePath = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                          if (image != null) {
                            setDialogState(() {
                              imagePath = image.path;
                              selectedEmoji = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(t.camera),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (image != null) {
                            setDialogState(() {
                              imagePath = image.path;
                              selectedEmoji = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.image, size: 18),
                        label: Text(t.galleryPicker),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (nameController.text.trim().isNotEmpty) {
                    try {
                      await sl<UpdateProductUseCase>()(
                        product: product,
                        newName: nameController.text.trim(),
                        emoji: selectedEmoji,
                        imagePath: imagePath,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {});
                      }
                    } on Failure catch (failure) {
                      if (context.mounted) Navigator.pop(context);
                      showFailureMessage(messenger, failure);
                    }
                  }
                },
                child: Text(t.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deleteProductConfirm(t.getProductName(product.nameKey))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await sl<DeleteProductUseCase>()(product);
                HapticFeedback.mediumImpact();
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              } on Failure catch (failure) {
                if (context.mounted) Navigator.pop(context);
                showFailureMessage(messenger, failure);
              }
            },
            child: Text(t.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleProduct(Product product, {Rect? fromRect}) async {
    try {
      await sl<ToggleProductUseCase>()(product);
      HapticFeedback.lightImpact();
      setState(() {});
      if (fromRect != null && mounted) {
        playProductMove(
          context,
          fromRect: fromRect,
          target: widget.isBuyScreen
              ? ProductMoveTarget.pantry
              : ProductMoveTarget.cart,
          preview: buildMovePreview(
            imagePath: product.imagePath,
            emoji: product.emoji ?? (widget.isBuyScreen ? '🛒' : '🏠'),
          ),
        );
      }
    } on Failure catch (failure) {
      if (mounted) showFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final t = AppLocalizations.of(context);
    final localizedName = t.getCategoryName(widget.category.key);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'category-circle-${widget.category.key}',
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.isBuyScreen
                      ? Colors.red.withValues(alpha: 0.25)
                      : Colors.green.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: CategoryVisuals.circleChild(
                    categoryKey: widget.category.key,
                    imagePath: widget.category.imagePath,
                    emoji: widget.category.emoji,
                    emojiSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                localizedName.toUpperCase(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: widget.isBuyScreen ? Colors.red.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      // El cuerpo reacciona al instante a los cambios del repositorio.
      body: StreamBuilder<List<Product>>(
        stream: sl<ProductRepository>().watchAll(),
        builder: (context, snapshot) {
          final uniqueMap = <String, Product>{};
          for (final product in snapshot.data ?? const <Product>[]) {
            if (product.categoryKey != widget.category.key) continue;
            if (product.isToBuy != widget.isBuyScreen) continue;
            uniqueMap['${product.categoryKey}_${product.nameKey.trim().toLowerCase()}_${product.isToBuy}'] = product;
          }
          final currentProducts = uniqueMap.values.toList();

          if (currentProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isBuyScreen ? '🛒' : '📦',
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.noProducts,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.emptyProductsSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return settings.isGridView
              ? GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: currentProducts.length,
            itemBuilder: (context, index) {
              final product = currentProducts[index];
              return KeyedSubtree(
                key: _rowKeyFor(product),
                child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _toggleProduct(product, fromRect: rectOfContext(_productRowKeys[product.id]?.currentContext)),
                  onLongPress: () => _showProductOptionsBottomSheet(context, product),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: ClipOval(
                              child: product.imagePath != null
                                  ? Image.file(File(product.imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                  : FittedBox(
                                fit: BoxFit.contain,
                                child: Text(
                                  product.emoji ?? (widget.isBuyScreen ? '🛒' : '🏠'),
                                  style: const TextStyle(fontSize: 50),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.getProductName(product.nameKey),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              );
            },
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: currentProducts.length,
            itemBuilder: (context, index) {
              final product = currentProducts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Dismissible(
                  key: Key('${product.id}_$index'),
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
                          rectOfContext(_productRowKeys[product.id]?.currentContext);
                      await _toggleProduct(product, fromRect: rowRect);
                      return false;
                    } else {
                      bool? delete = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(t.delete),
                          content: Text(t.deleteProductConfirm(t.getProductName(product.nameKey))),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(t.cancel),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(t.delete),
                            ),
                          ],
                        ),
                      );
                      if (delete == true) {
                        await sl<DeleteProductUseCase>()(product);
                        HapticFeedback.mediumImpact();
                        setState(() {});
                        return true;
                      }
                      return false;
                    }
                  },
                  child: KeyedSubtree(
                    key: _rowKeyFor(product),
                    child: InkWell(
                      onTap: () => _toggleProduct(product, fromRect: rectOfContext(_productRowKeys[product.id]?.currentContext)),
                      onLongPress: () => _showProductOptionsBottomSheet(context, product),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: product.imagePath != null
                              ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                              : Center(
                            child: Text(
                              product.emoji ?? (widget.isBuyScreen ? '🛒' : '🏠'),
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        t.getProductName(product.nameKey),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.isBuyScreen ? Colors.red.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddProductDialog(
              categories: [widget.category.key],
              initialCategory: widget.category.key,
              isBuyScreen: widget.isBuyScreen,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
