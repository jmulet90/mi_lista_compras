import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/image_storage.dart';
import '../../core/utils/product_asset_catalog.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/rename_category.dart';
import '../../domain/usecases/update_product.dart';
import '../app_settings.dart';
import '../localization/app_localizations.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_visuals.dart';
import '../widgets/dialog_kit.dart';
import '../widgets/expandable_category_card.dart';
import '../widgets/premium_limits.dart';
import '../widgets/show_failure.dart';
import 'category_detail_screen.dart';

class CategoryContainerScreen extends StatefulWidget {
  final bool isBuyScreen;
  final List<Product> products;
  final List<CategoryItem> categories;
  final bool isLoading;

  const CategoryContainerScreen({
    super.key,
    required this.isBuyScreen,
    required this.products,
    required this.categories,
    this.isLoading = false,
  });

  @override
  State<CategoryContainerScreen> createState() => _CategoryContainerScreenState();
}

class _CategoryContainerScreenState extends State<CategoryContainerScreen> with TickerProviderStateMixin {
  bool _isFabOpen = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _expandAnimation;

  bool _isViewFabOpen = false;
  late final AnimationController _viewFabController;
  late final Animation<double> _viewExpandAnimation;



  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      value: _isFabOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _viewFabController = AnimationController(
      value: _isViewFabOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _viewExpandAnimation = CurvedAnimation(
      parent: _viewFabController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _viewFabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _toggleViewFab() {
    setState(() {
      _isViewFabOpen = !_isViewFabOpen;
      if (_isViewFabOpen) {
        _viewFabController.forward();
      } else {
        _viewFabController.reverse();
      }
    });
  }

  Future<void> _applyViewMode(bool isGridView) async {
    HapticFeedback.selectionClick();
    if (!PremiumLimits.checkCanEdit(context)) return;
    final notifier = AppSettings.notifierOf(context);
    if (isGridView &&
        !await PremiumLimits.canUseAppearanceFeature(context)) {
      return;
    }
    notifier.value = notifier.value.copyWith(isGridView: isGridView);
    if (_isViewFabOpen) _toggleViewFab();
  }

  void _showAdvancedAddProductDialog(BuildContext context, {String? initialCategoryKey}) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        categories: widget.categories.map((c) => c.key).toList(),
        initialCategory: initialCategoryKey,
        isBuyScreen: widget.isBuyScreen,
      ),
    );
  }

  Future<void> _showAdvancedAddCategoryDialog(BuildContext context) async {
    if (!PremiumLimits.checkCanEdit(context)) return;
    if (!await PremiumLimits.canAddCategory(context)) return;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );
  }

  void _showEditCategoryDialog(BuildContext context, CategoryItem category) {
    final t = AppLocalizations.of(context);
    const accent = DialogAccents.emerald;
    final nameController = TextEditingController(text: t.getCategoryName(category.key));
    String? selectedEmoji = category.emoji;
    String? imagePath = category.imagePath;
    const List<String> emojis = ['ðŸ²', 'ðŸ¥©', 'â˜•', 'ðŸ¥', 'ðŸ§€', 'ðŸž', 'ðŸ¥ž', 'ðŸ¥“',  'ðŸŽ', 'ðŸŒ', 'ðŸ¥¦', 'ðŸ¥”','ðŸ¥‚', 'ðŸ·', 'ðŸº', 'ðŸ§ƒ', 'ðŸ¥›', 'â˜•', 'ðŸ«–', 'ðŸ§½', 'âœ¨', 'ðŸ§¼', 'ðŸ§»', 'ðŸ§¹', 'ðŸ§º',  'ðŸ“¦', 'ðŸ›’', 'ðŸ ', 'ðŸ’¡', 'ðŸ¾', 'ðŸ’Š', 'ðŸ¼', 'ðŸ”‹'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return DialogKit.frame(
            context,
            title: Text(t.editCategory),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: DialogKit.input(context, accent, label: t.editCategory),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: DialogKit.previewCircle(
                      accent: accent,
                      imagePath: imagePath,
                      emoji: selectedEmoji ?? 'ðŸ“¦',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
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
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(t.camera),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
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
                        icon: const Icon(Icons.image, size: 18),
                        label: Text(t.galleryPicker),
                      ),
                    ],
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
                      await sl<RenameCategoryUseCase>()(
                        category: category,
                        newName:
                            AppLocalizations.findNameKey(nameController.text.trim()) ??
                                nameController.text.trim(),
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
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryItem category) {
    final t = AppLocalizations.of(context);
    final localizedName = t.getCategoryName(category.key);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteCategory),
        content: Text(t.deleteCategoryConfirm(localizedName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await sl<DeleteCategoryUseCase>()(category);
                if (context.mounted) Navigator.pop(context);
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

  void _showEditProductDialog(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);
    final nameController =
        TextEditingController(text: t.getProductName(product.nameKey));

    String? selectedEmoji = product.emoji;
    String? imagePath = product.imagePath;
    double? quantity = product.quantity;
    String? unit = product.unit;

    final pngs = ProductAssetCatalog.instance.pngsFor(product.categoryKey);
    if (pngs.isNotEmpty && !pngs.contains(selectedEmoji)) {
      selectedEmoji = imagePath == null ? pngs.first : null;
    } else if (pngs.isEmpty) {
      selectedEmoji = null;
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
                      emoji: selectedEmoji,
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
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
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
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(t.camera),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
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
                        icon: const Icon(Icons.image, size: 18),
                        label: Text(t.galleryPicker),
                      ),
                    ],
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
                        newName:
                            AppLocalizations.findNameKey(nameController.text.trim()) ??
                                nameController.text.trim(),
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
                if (context.mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final t = AppLocalizations.of(context);
    final title = widget.isBuyScreen ? t.buyTitle : t.stockTitle;
    final isBuy = widget.isBuyScreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isBuy ? const Color(0xFFE11D48) : const Color(0xFF059669);
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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: Listenable.merge([_expandAnimation, _viewExpandAnimation]),
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Opciones de vistas: crecen pegadas al botÃ³n de vistas.
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.bottomCenter,
                child: _isViewFabOpen
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FloatingActionButton.extended(
                            heroTag: 'btn_view_list',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey.shade800,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            onPressed: () => _applyViewMode(false),
                            icon: const Icon(Icons.view_list),
                            label: Row(
                              children: [
                                Text(t.list),
                                if (!settings.isGridView) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.extended(
                            heroTag: 'btn_view_gallery',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey.shade800,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            onPressed: () => _applyViewMode(true),
                            icon: const Icon(Icons.grid_view),
                            label: Row(
                              children: [
                                Text(t.gallery),
                                if (settings.isGridView) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              // BotÃ³n de vistas; sube cuando se despliega el abanico de crear.
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: FloatingActionButton(
                  heroTag: 'btn_view_mode',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueGrey.shade800,
                  elevation: 4,
                  shape: const CircleBorder(),
                  onPressed: () {
                    if (!PremiumLimits.checkCanEdit(context)) return;
                    _toggleViewFab();
                  },
                  child: Transform.rotate(
                    angle: _viewExpandAnimation.value * 0.785398,
                    child: Icon(
                      settings.isGridView ? Icons.grid_view : Icons.view_list,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Abanico de crear: entre el botÃ³n principal y el de vistas.
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.bottomCenter,
                child: _isFabOpen
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FloatingActionButton.extended(
                            heroTag: 'btn_category',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey.shade800,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            onPressed: () {
                              _toggleFab();
                              _showAdvancedAddCategoryDialog(context);
                            },
                            icon: const Icon(Icons.create_new_folder_outlined, size: 22),
                            label: Text(
                              t.addCategory,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.extended(
                            heroTag: 'btn_product',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey.shade800,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            onPressed: () {
                              if (!PremiumLimits.checkCanEdit(context)) return;
                              _toggleFab();
                              _showAdvancedAddProductDialog(context);
                            },
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 22),
                            label: Text(
                              t.newProduct,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'btn_main',
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                onPressed: () {
                  if (!PremiumLimits.checkCanEdit(context)) return;
                  _toggleFab();
                },
                child: Transform.rotate(
                  angle: _expandAnimation.value * 0.785398,
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            ],
          );
        },
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: widget.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: widget.isBuyScreen ? const Color(0xFFE11D48) : const Color(0xFF059669),
              ),
            )
          : widget.categories.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 72,
                      color: isDark ? Colors.white24 : Colors.blueGrey.shade200,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.noCategories,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.blueGrey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.emptyCategoriesSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _showAdvancedAddCategoryDialog(context),
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: Text(t.addCategory),
                    ),
                  ],
                ),
              ),
            )
          : settings.isGridView
              ? GridView.builder(
              key: const ValueKey('grid'),
              padding: const EdgeInsets.all(12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.82,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final catItem = widget.categories[index];
          final localizedCategoryName = t.getCategoryName(catItem.key);
          final catProducts = widget.products.where((p) => p.categoryKey == catItem.key && p.isToBuy == widget.isBuyScreen).toList();

          final hasProducts = catProducts.isNotEmpty;
          final activeColor = widget.isBuyScreen ? Colors.red : Colors.green;

          return _StaggeredItem(
            index: index,
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
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailScreen(
                      category: catItem,
                      isBuyScreen: widget.isBuyScreen,
                    ),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
              onLongPress: () {
                if (!PremiumLimits.checkCanEdit(context)) return;
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit, color: Colors.blueGrey),
                          title: Text('${t.edit} "$localizedCategoryName"'),
                          onTap: () {
                            Navigator.pop(context);
                            _showEditCategoryDialog(context, catItem);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: Text('${t.delete} "$localizedCategoryName"'),
                          onTap: () {
                            Navigator.pop(context);
                            _confirmDeleteCategory(context, catItem);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Hero(
                              tag: 'category-circle-${catItem.key}',
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: hasProducts
                                      ? activeColor.withValues(alpha: 0.10)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.grey.shade100),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: hasProducts
                                        ? activeColor.withValues(alpha: 0.35)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: CategoryVisuals.circleChild(
                                    categoryKey: catItem.key,
                                    imagePath: catItem.imagePath,
                                    emoji: catItem.emoji,
                                    emojiSize: 65,
                                  ),
                                ),
                              ),
                            ),
                            if (catProducts.isNotEmpty)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: activeColor,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '${catProducts.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      localizedCategoryName,
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
        );
        },
      )
          : ListView.builder(
              key: const ValueKey('list'),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
          final catItem = widget.categories[index];
          final localizedCategoryName = t.getCategoryName(catItem.key);
          final catProducts = widget.products.where((p) => p.categoryKey == catItem.key && p.isToBuy == widget.isBuyScreen).toList();

          return _StaggeredItem(
            index: index,
            child: ExpandableCategoryCard(
            catItem: catItem,
            localizedCategoryName: localizedCategoryName,
            catProducts: catProducts,
            isBuyScreen: widget.isBuyScreen,
            t: t,
            onTapCard: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(
                    category: catItem,
                    isBuyScreen: widget.isBuyScreen,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            onLongPressCard: () {
              if (!PremiumLimits.checkCanEdit(context)) return;
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit, color: Colors.blueGrey),
                        title: Text('${t.edit} "$localizedCategoryName"'),
                        onTap: () {
                          Navigator.pop(context);
                          _showEditCategoryDialog(context, catItem);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: Text('${t.delete} "$localizedCategoryName"'),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDeleteCategory(context, catItem);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            onEditProduct: _showEditProductDialog,
            onDeleteProduct: _confirmDeleteProduct,
          ),
        );
              },
            ),
          ),
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final delayMs = (widget.index * 45).clamp(0, 450);
    Future.delayed(Duration(milliseconds: delayMs), () {
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
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _animation.value) * 24),
            child: child,
          ),
        );
      },
    );
  }
}
