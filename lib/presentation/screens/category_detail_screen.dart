import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/image_storage.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/toggle_product.dart';
import '../../domain/usecases/update_product.dart';
import '../../domain/repositories/product_repository.dart';
import '../app_settings.dart';
import '../localization/app_localizations.dart';
import '../widgets/premium_limits.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/category_visuals.dart';
import '../widgets/dialog_kit.dart';
import '../widgets/product_visuals.dart';
import '../../core/utils/product_asset_catalog.dart';
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
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);
    final nameController =
        TextEditingController(text: t.getProductName(product.nameKey));
    String? selectedEmoji = product.emoji ?? '📦';
    String? imagePath = product.imagePath;
    double? quantity = product.quantity;
    String? unit = product.unit;
    const List<String> emojis = ['🥛', '🍞', '🍎', '🍐', '🍊', '🍋', '🍉', '🍇', '🍓', '🫐', '🍒', '🥭','🍍', '🥥', '🥝', '🥑', '🥩', '☕', '🥐', '🧀', '🍌', '🍅', '🧻', '🧼', '🧊'];
    final pngs = ProductAssetCatalog.instance.pngsFor(product.categoryKey);
    if (pngs.isNotEmpty && !pngs.contains(selectedEmoji)) {
      selectedEmoji = imagePath == null ? pngs.first : null;
    } else if (pngs.isEmpty && DialogKit.isAssetRef(selectedEmoji)) {
      selectedEmoji = emojis.first;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return DialogKit.frame(
            context,
            title: Text(t.edit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: DialogKit.input(context, accent, label: t.edit),
                  ),
                  const SizedBox(height: 16),
                  DialogKit.quantityUnitRow(
                    context: context,
                    accent: accent,
                    quantity: quantity,
                    unit: unit,
                    onQuantityChanged: (val) => setDialogState(() => quantity = val),
                    onUnitChanged: (val) => setDialogState(() => unit = val),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: DialogKit.previewCircle(
                      accent: accent,
                      imagePath: imagePath,
                      emoji: selectedEmoji ?? '📦',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(t.visualCustomization, style: TextStyle(fontSize: 12, color: DialogKit.isDark(context) ? Colors.grey.shade400 : Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  if (pngs.isNotEmpty)
                    DialogKit.assetStrip(
                      context: context,
                      accent: accent,
                      assets: pngs,
                      selected: imagePath == null ? selectedEmoji : null,
                      onSelect: (asset) {
                        setDialogState(() {
                          selectedEmoji = asset;
                          imagePath = null;
                        });
                      },
                    )
                  else
                    DialogKit.emojiStrip(
                      context: context,
                      accent: accent,
                      emojis: emojis,
                      selected: imagePath == null ? selectedEmoji : null,
                      onSelect: (emoji) {
                        setDialogState(() {
                          selectedEmoji = emoji;
                          imagePath = null;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  DialogKit.mediaRow(
                    context,
                    cameraLabel: t.camera,
                    galleryLabel: t.galleryPicker,
                    onCamera: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,
                        maxWidth: 1200,
                        maxHeight: 1200,
                      );
                      final savedPath = await persistPickedImage(image);
                      if (savedPath != null) {
                        setDialogState(() {
                          imagePath = savedPath;
                          selectedEmoji = null;
                        });
                      }
                    },
                    onGallery: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                        maxWidth: 1200,
                        maxHeight: 1200,
                      );
                      final savedPath = await persistPickedImage(image);
                      if (savedPath != null) {
                        setDialogState(() {
                          imagePath = savedPath;
                          selectedEmoji = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              DialogKit.cancelButton(context, t.cancel),
              DialogKit.saveButton(
                context,
                t.save,
                accent,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (nameController.text.trim().isNotEmpty) {
                    try {
                      await sl<UpdateProductUseCase>()(
                        product: product,
                        newName: nameController.text.trim(),
                        emoji: selectedEmoji,
                        imagePath: imagePath,
                        quantity: quantity,
                        unit: unit,
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

  void _showQtyUnitDialog(Product product) async {
    if (!await PremiumLimits.canUseQuantityFeature(context)) return;
    if (!mounted) return;
    final t = AppLocalizations.of(context);
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: t.quantityLabel,
                  hintText: 'Ej: 2',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    quantity: qty ?? 0,
                    unit: unit,
                  );
                  if (mounted) setState(() {});
                  if (qty != null && mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Cantidad: ${DialogKit.formatQuantity(qty!)}${unit != null ? ' $unit' : ''}'),
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

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final t = AppLocalizations.of(context);
    final localizedName = t.getCategoryName(widget.category.key);
    final isBuy = widget.isBuyScreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = DialogKit.accentForBuy(isBuy);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? (isBuy
              ? const [Color(0xFF27141B), Color(0xFF141018)]
              : const [Color(0xFF11281F), Color(0xFF131712)])
          : (isBuy
              ? const [Color(0xFFFFF1F2), Color(0xFFFCF8F8)]
              : const [Color(0xFFEAFBF3), Color(0xFFF7FBF9)]),
    );

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
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1.6,
                  ),
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
                localizedName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      // El cuerpo reacciona al instante a los cambios del repositorio.
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: StreamBuilder<List<Product>>(
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
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade100 : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.emptyProductsSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
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
              childAspectRatio: 0.72,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: currentProducts.length,
            itemBuilder: (context, index) {
              final product = currentProducts[index];
              return KeyedSubtree(
                key: _rowKeyFor(product),
                child: Dismissible(
                  key: Key('grid_${product.id}_$index'),
                  background: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.swap_horiz, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(20),
                    ),
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
                        builder: (ctx) => DialogKit.frame(
                          ctx,
                          title: Text(t.delete),
                          content: Text(t.deleteProductConfirm(t.getProductName(product.nameKey))),
                          actions: [
                            DialogKit.cancelButton(
                              ctx,
                              t.cancel,
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                            DialogKit.saveButton(
                              ctx,
                              t.delete,
                              DialogAccents.rose,
                              onPressed: () => Navigator.pop(ctx, true),
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
                  child: Card(
                  elevation: 0,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.62),
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showQtyUnitDialog(product),
                    onLongPress: () => _showProductOptionsBottomSheet(context, product),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 112,
                                height: 112,
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
                                    emojiSize: 80,
                                    fallbackEmoji:
                                        widget.isBuyScreen ? '🛒' : '🏠',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (product.quantity != null && PremiumLimits.isPremium)
                            Text(
                              '${DialogKit.formatQuantity(product.quantity!)}${product.unit != null ? ' ${product.unit}' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.1,
                                color: accent,
                              ),
                            ),
                          Text(
                            t.getProductName(product.nameKey),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              letterSpacing: 0.1,
                              color: isDark ? Colors.grey.shade200 : const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                elevation: 0,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.62),
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Dismissible(
                  key: Key('${product.id}_$index'),
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
                      final rowRect =
                          rectOfContext(_productRowKeys[product.id]?.currentContext);
                      await _toggleProduct(product, fromRect: rowRect);
                      return false;
                    } else {
                      bool? delete = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => DialogKit.frame(
                          ctx,
                          title: Text(t.delete),
                          content: Text(t.deleteProductConfirm(t.getProductName(product.nameKey))),
                          actions: [
                            DialogKit.cancelButton(
                              ctx,
                              t.cancel,
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                            DialogKit.saveButton(
                              ctx,
                              t.delete,
                              DialogAccents.rose,
                              onPressed: () => Navigator.pop(ctx, true),
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
                      onLongPress: () => _showProductOptionsBottomSheet(context, product),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
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
                                  emojiSize: 48,
                                  fallbackEmoji: widget.isBuyScreen ? '🛒' : '🏠',
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                t.getProductName(product.nameKey),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  letterSpacing: -0.1,
                                  color: isDark ? Colors.grey.shade100 : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _InlineQtyUnitDetail(
                              product: product,
                              accent: accent,
                            ),
                          ],
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
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

class _InlineQtyUnitDetail extends StatefulWidget {
  final Product product;
  final Color accent;

  const _InlineQtyUnitDetail({
    required this.product,
    required this.accent,
  });

  @override
  State<_InlineQtyUnitDetail> createState() => _InlineQtyUnitDetailState();
}

class _InlineQtyUnitDetailState extends State<_InlineQtyUnitDetail> {
  late double? _qty;
  late String? _unit;

  @override
  void initState() {
    super.initState();
    _qty = widget.product.quantity;
    _unit = widget.product.unit;
  }

  @override
  void didUpdateWidget(covariant _InlineQtyUnitDetail oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textSub = dark ? Colors.grey.shade400 : Colors.grey.shade600;
    final showQty = _qty != null && PremiumLimits.isPremium;

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
}

