import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/image_storage.dart';
import '../../core/utils/product_asset_catalog.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/subcategory_item.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/subcategory_repository.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/rename_category.dart';
import '../../domain/usecases/update_product.dart';
import '../app_settings.dart';
import '../localization/app_localizations.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/floating_nav_spec.dart';
import '../services/shopping_list_exporter.dart';
import '../services/subcategory_actions.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/action_sheet_menu.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_visuals.dart';
import '../widgets/dialog_kit.dart';
import '../widgets/expandable_category_card.dart';
import '../widgets/notification_bell_icon.dart';
import '../widgets/premium_limits.dart';
import '../widgets/show_failure.dart';
import '../widgets/subcategory_selector.dart';
import '../widgets/subcategory_dialog.dart';
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
  State<CategoryContainerScreen> createState() =>
      _CategoryContainerScreenState();
}

class _CategoryContainerScreenState extends State<CategoryContainerScreen>
    with TickerProviderStateMixin {
  bool _isFabOpen = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _expandAnimation;

  bool _isViewFabOpen = false;
  late final AnimationController _viewFabController;
  late final Animation<double> _viewExpandAnimation;

  /// Popup de exportar anclado al botÃ³n de compartir (AppBar).
  final GlobalKey _exportKey = GlobalKey();
  bool _isExportOpen = false;
  OverlayEntry? _exportOverlay;

  /// Contexto del acordeÃ³n: categorÃ­a expandida y subcategorÃ­a expandida.
  /// `_expandedSubcategory` es null (nada expandido), '' ("Sin subcategorÃ­a")
  /// o el nombre de una subcategorÃ­a.
  String? _expandedCategoryKey;
  String? _expandedSubcategory;

  /// SubcategorÃ­as persistidas por categorÃ­a (clave = categorÃ­a en minÃºsculas).
  Map<String, List<SubcategoryItem>> _subcategories = {};
  StreamSubscription<Map<String, List<SubcategoryItem>>>? _subcategoriesSub;

  List<SubcategoryItem> _subcategoriesOf(CategoryItem catItem) =>
      _subcategories[catItem.key.trim().toLowerCase()] ?? const [];

  /// Cantidad de subcategorÃ­as distintas de [catItem] (persistidas + las que
  /// aparecen en sus productos). Exclusivo Premium Plus: sin el plan siempre
  /// devuelve 0, para no insinuar una funciÃ³n bloqueada dentro de la tarjeta.
  int _subcategoryCountOf(CategoryItem catItem, List<Product> catProducts) {
    if (!PremiumLimits.isPremiumPlusEffectiveSync) return 0;
    return SubcategoryActions.visibleSubs(catProducts).length;
  }

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

    _subcategoriesSub = sl<SubcategoryRepository>().watchAll().listen((map) {
      if (mounted) setState(() => _subcategories = map);
    });
  }

  @override
  void dispose() {
    _subcategoriesSub?.cancel();
    _exportOverlay?.remove();
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

  /// Opciones del abanico de crear segÃºn el contexto del acordeÃ³n:
  /// - Ninguna categorÃ­a expandida â†’ solo "crear categorÃ­a".
  /// - CategorÃ­a expandida (sin subcategorÃ­a) â†’ "nueva subcategorÃ­a" y "nuevo producto".
  /// - SubcategorÃ­a expandida â†’ solo "nuevo producto" (en esa subcategorÃ­a).
  List<Widget> _createFanOptions(
    BuildContext context,
    AppLocalizations t, {
    required bool inCategory,
    required bool inSubcategory,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final options =
        <({String heroTag, IconData icon, String label, VoidCallback onTap})>[];

    if (!inCategory) {
      options.add((
        heroTag: 'btn_category',
        icon: Icons.create_new_folder_outlined,
        label: t.addCategory,
        onTap: () {
          _toggleFab();
          _showAdvancedAddCategoryDialog(context);
        },
      ));
    } else if (!inSubcategory) {
      options.add((
        heroTag: 'btn_subcategory',
        icon: Icons.create_new_folder_outlined,
        label: t.newSubcategory,
        onTap: () {
          _toggleFab();
          _showAddSubcategoryDialog(context);
        },
      ));
      options.add((
        heroTag: 'btn_product',
        icon: Icons.add_shopping_cart_rounded,
        label: t.newProduct,
        onTap: () {
          if (!PremiumLimits.checkCanEdit(context)) return;
          _toggleFab();
          _showAdvancedAddProductDialog(
            context,
            initialCategoryKey: _expandedCategoryKey,
          );
        },
      ));
    } else {
      options.add((
        heroTag: 'btn_product',
        icon: Icons.add_shopping_cart_rounded,
        label: t.newProduct,
        onTap: () {
          if (!PremiumLimits.checkCanEdit(context)) return;
          _toggleFab();
          _showAdvancedAddProductDialog(
            context,
            initialCategoryKey: _expandedCategoryKey,
            initialSubcategory: _expandedSubcategory == ''
                ? null
                : _expandedSubcategory,
          );
        },
      ));
    }

    final buttons = <Widget>[];
    for (var i = 0; i < options.length; i++) {
      final o = options[i];
      buttons.add(
        _FanOption(
          delay: Duration(milliseconds: 60 * i),
          child: FloatingActionButton.extended(
            heroTag: o.heroTag,
            backgroundColor: dark ? const Color(0xFF1E293B) : Colors.white,
            foregroundColor: dark
                ? Colors.grey.shade100
                : Colors.blueGrey.shade800,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: dark
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.12))
                  : BorderSide.none,
            ),
            onPressed: o.onTap,
            icon: Icon(o.icon, size: 22),
            label: Text(
              o.label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      );
      if (i < options.length - 1) buttons.add(const SizedBox(height: 8));
    }
    return buttons;
  }

  Future<void> _applyViewMode(bool isGridView) async {
    HapticFeedback.selectionClick();
    if (!PremiumLimits.checkCanEdit(context)) return;
    final notifier = AppSettings.notifierOf(context);
    if (isGridView && !await PremiumLimits.canUseAppearanceFeature(context)) {
      return;
    }
    notifier.value = notifier.value.copyWith(isGridView: isGridView);
    if (_isViewFabOpen) _toggleViewFab();
  }

  void _onToggleExpanded(String categoryKey, bool wantExpanded) {
    setState(() {
      if (wantExpanded) {
        _expandedCategoryKey = categoryKey;
        _expandedSubcategory = null;
      } else {
        _expandedCategoryKey = null;
        _expandedSubcategory = null;
      }
    });
  }

  void _onToggleSubcategory(String? value) {
    setState(() {
      _expandedSubcategory = (_expandedSubcategory == value) ? null : value;
    });
  }

  void _showAdvancedAddProductDialog(
    BuildContext context, {
    String? initialCategoryKey,
    String? initialSubcategory,
  }) {
    /// Asegurarse de que la categorÃ­a expandida siempre estÃ© en la lista,
    /// incluso si es una categorÃ­a nueva que aÃºn no aparece en widget.categories
    final allCategories = <String>[];
    if (widget.categories.isNotEmpty) {
      allCategories.addAll(widget.categories.map((c) => c.key));
    }

    /// Agregar la categorÃ­a expandida si existe y no estÃ¡ ya en la lista
    if (initialCategoryKey != null &&
        !allCategories.contains(initialCategoryKey)) {
      allCategories.add(initialCategoryKey);
    }

    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        categories: allCategories,
        initialCategory: initialCategoryKey,
        initialSubcategory: initialSubcategory,
        isBuyScreen: widget.isBuyScreen,
      ),
    );
  }

  /// Crea una subcategorÃ­a en la categorÃ­a expandida. Las subcategorÃ­as son
  /// Premium Plus: los usuarios sin Plus ven el paywall (bloqueado con aviso).
  Future<void> _showAddSubcategoryDialog(BuildContext context) async {
    final t = AppLocalizations.of(context);
    if (_expandedCategoryKey == null) return;
    if (!await PremiumLimits.canUsePremiumPlus(
      context,
      reason: t.plusExclusive,
    )) {
      return;
    }
    if (!context.mounted) return;
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          SubcategoryDialog(categoryKey: _expandedCategoryKey!, accent: accent),
    );
    if (!context.mounted) return;
    if (name == null || name.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${t.subcategory}: $name'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _doExport(BuildContext context, String choice) async {
    final t = AppLocalizations.of(context);
    if (!await PremiumLimits.canUsePremiumPlus(
      context,
      reason: t.plusExclusive,
    )) {
      return;
    }
    if (!context.mounted) return;
    if (choice == 'pdf') {
      await ShoppingListExporter.exportAsPdf(
        context: context,
        products: widget.products,
        categories: widget.categories,
      );
    } else if (choice == 'img') {
      await ShoppingListExporter.exportAsImage(
        context: context,
        products: widget.products,
        categories: widget.categories,
      );
    }
  }

  /// Abre o cierra el popup de exportar anclado justo debajo del botÃ³n de
  /// compartir del AppBar, con la misma animaciÃ³n que el abanico de FABs.
  void _toggleExportPopup() {
    if (_isExportOpen) {
      _closeExportPopup();
      return;
    }
    final overlay = Overlay.of(context);
    _exportOverlay = OverlayEntry(
      builder: (overlayContext) {
        return _buildExportOverlay(overlayContext);
      },
    );
    overlay.insert(_exportOverlay!);
    setState(() => _isExportOpen = true);
  }

  void _closeExportPopup() {
    _exportOverlay?.remove();
    _exportOverlay = null;
    if (mounted) setState(() => _isExportOpen = false);
  }

  /// Construye el overlay del popup de exportar. Calcula la posiciÃ³n del botÃ³n
  /// de compartir (el ancla) y despliega los 2 botones pegados debajo de Ã©l.
  Widget _buildExportOverlay(BuildContext overlayContext) {
    final t = AppLocalizations.of(overlayContext);
    final isDark = Theme.of(overlayContext).brightness == Brightness.dark;
    final box = _exportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !_exportKey.currentContext!.mounted) {
      return const SizedBox.shrink();
    }
    final overlayBox =
        Overlay.of(overlayContext).context.findRenderObject() as RenderBox;
    final target = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    const popupWidth = 190.0;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _closeExportPopup(),
          ),
        ),
        Positioned(
          left: (target.dx + box.size.width - popupWidth).clamp(
            8.0,
            overlayBox.size.width - popupWidth - 8.0,
          ),
          top: target.dy + box.size.height + 8,
          width: popupWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _FanOption(
                delay: Duration.zero,
                dropDown: true,
                child: FloatingActionButton.extended(
                  heroTag: 'btn_export_pdf',
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: isDark
                      ? Colors.grey.shade100
                      : Colors.blueGrey.shade800,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: isDark
                        ? BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          )
                        : BorderSide.none,
                  ),
                  onPressed: () {
                    _closeExportPopup();
                    _doExport(context, 'pdf');
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 22),
                  label: Text(
                    t.exportAsPdf,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _FanOption(
                delay: const Duration(milliseconds: 60),
                dropDown: true,
                child: FloatingActionButton.extended(
                  heroTag: 'btn_export_img',
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: isDark
                      ? Colors.grey.shade100
                      : Colors.blueGrey.shade800,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: isDark
                        ? BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          )
                        : BorderSide.none,
                  ),
                  onPressed: () {
                    _closeExportPopup();
                    _doExport(context, 'img');
                  },
                  icon: const Icon(Icons.image, size: 22),
                  label: Text(
                    t.exportAsImage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  String? _autoPngForEdit(
    String text,
    String? selectedEmoji,
    String? imagePath,
  ) {
    if (text.trim().isNotEmpty && imagePath == null) {
      final key = AppLocalizations.findNameKey(text.trim());
      if (key != null) {
        final asset = CategoryVisuals.assetFor(key);
        if (asset != null) return asset;
      }
    }
    return selectedEmoji;
  }

  void _showEditCategoryDialog(BuildContext context, CategoryItem category) {
    final t = AppLocalizations.of(context);
    const accent = DialogAccents.emerald;
    final nameController = TextEditingController(
      text: t.getCategoryName(category.key),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String? selectedEmoji = category.emoji;
          String? imagePath = category.imagePath;

          /// Auto-detect PNG por nombre al iniciar o al cambiar el texto
          selectedEmoji = _autoPngForEdit(
            nameController.text,
            selectedEmoji,
            imagePath,
          );

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
                    decoration: DialogKit.input(
                      context,
                      accent,
                      label: t.editCategory,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: DialogKit.previewCircle(
                      accent: accent,
                      imagePath: imagePath,
                      emoji: selectedEmoji ?? CategoryVisuals.assets.first,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DialogKit.assetStrip(
                    context: context,
                    accent: accent,
                    assets: CategoryVisuals.assets,
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
                  final text = nameController.text.trim();
                  if (text.isNotEmpty) {
                    final newKey =
                        AppLocalizations.findNameKey(text) ?? text;
                    // El renombrado a un nombre ya ocupado antes se
                    // comportaba mal (sobrescribía otra categoría): aquí se
                    // bloquea con un aviso claro.
                    if (newKey.trim().toLowerCase() !=
                            category.key.trim().toLowerCase() &&
                        await sl<CategoryRepository>().exists(newKey)) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(t.categoryAlreadyExists),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    try {
                      await sl<RenameCategoryUseCase>()(
                        category: category,
                        newName: newKey,
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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

  /// Menú de categoría al hacer long press (Editar/Borrar) con el mismo
  /// diseño y animación que el popup de exportar PDF/Imagen.
  void _showCategoryActionsSheet(
    BuildContext context,
    CategoryItem catItem,
    String localizedCategoryName,
  ) {
    final t = AppLocalizations.of(context);
    ActionSheetMenu.show(
      context,
      options: [
        ActionSheetOption(
          icon: Icons.edit,
          label: '${t.edit} "$localizedCategoryName"',
          color: const Color(0xFF52606D),
          onTap: () {
            Navigator.pop(context);
            _showEditCategoryDialog(context, catItem);
          },
        ),
        ActionSheetOption(
          icon: Icons.delete,
          label: '${t.delete} "$localizedCategoryName"',
          color: const Color(0xFFE11D48),
          onTap: () {
            Navigator.pop(context);
            _confirmDeleteCategory(context, catItem);
          },
        ),
      ],
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);
    final nameController = TextEditingController(
      text: t.getProductName(product.nameKey),
    );

    String? selectedEmoji = product.emoji;
    String? imagePath = product.imagePath;
    String? subcategory = product.subcategory;

    final isPlus = PremiumLimits.isPremiumPlusEffectiveSync;

    final existingSubs = <String>{};
    for (final p in widget.products.where(
      (p) => p.categoryKey == product.categoryKey,
    )) {
      final sub = p.subcategory?.trim();
      if (sub != null && sub.isNotEmpty) {
        existingSubs.add(sub);
      }
    }
    existingSubs.addAll([
      for (final s
          in _subcategories[product.categoryKey.trim().toLowerCase()] ??
              const <SubcategoryItem>[])
        s.name,
    ]);
    final sortedSubs = existingSubs.toList()..sort();

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
                  if (isPlus) ...[
                    const SizedBox(height: 16),
                    SubcategorySelector(
                      categoryKey: product.categoryKey,
                      existing: sortedSubs,
                      value: subcategory,
                      accent: accent,
                      onChanged: (val) =>
                          setDialogState(() => subcategory = val),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: DialogKit.previewCircle(
                      accent: accent,
                      imagePath: imagePath,
                      emoji: selectedEmoji,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.visualCustomization,
                    style: TextStyle(
                      fontSize: 12,
                      color: DialogKit.isDark(context)
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
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
                            AppLocalizations.findNameKey(
                              nameController.text.trim(),
                            ) ??
                            nameController.text.trim(),
                        emoji: selectedEmoji,
                        imagePath: imagePath,
                        quantity: product.quantity,
                        unit: product.unit,
                        subcategory: subcategory,
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
      // El FAB debe flotar por encima de la barra inferior flotante.
      floatingActionButtonLocation: FloatingFabLocation(
        FloatingNavSpec.fabLift(),
      ),
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
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        actions: [
          if (widget.isBuyScreen)
            IconButton(
              key: _exportKey,
              tooltip: t.exportList,
              icon: const Icon(Icons.ios_share),
              onPressed: () => _toggleExportPopup(),
            ),
          const NotificationBellIcon(),
        ],
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
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            foregroundColor: isDark
                                ? Colors.grey.shade100
                                : Colors.blueGrey.shade800,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: isDark
                                  ? BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    )
                                  : BorderSide.none,
                            ),
                            onPressed: () => _applyViewMode(false),
                            icon: const Icon(Icons.view_list),
                            label: Row(
                              children: [
                                Text(t.list),
                                if (!settings.isGridView) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.extended(
                            heroTag: 'btn_view_gallery',
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            foregroundColor: isDark
                                ? Colors.grey.shade100
                                : Colors.blueGrey.shade800,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: isDark
                                  ? BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    )
                                  : BorderSide.none,
                            ),
                            onPressed: () => _applyViewMode(true),
                            icon: const Icon(Icons.grid_view),
                            label: Row(
                              children: [
                                Text(t.gallery),
                                if (settings.isGridView) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
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
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: isDark
                      ? Colors.grey.shade100
                      : Colors.blueGrey.shade800,
                  elevation: 4,
                  shape: CircleBorder(
                    side: isDark
                        ? BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          )
                        : BorderSide.none,
                  ),
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
                        children: _createFanOptions(
                          context,
                          t,
                          inCategory: widget.categories.any(
                            (c) => c.key == _expandedCategoryKey,
                          ),
                          inSubcategory:
                              widget.categories.any(
                                (c) => c.key == _expandedCategoryKey,
                              ) &&
                              _expandedSubcategory != null,
                        ),
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
        child: Stack(
          children: [
            widget.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: widget.isBuyScreen
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF059669),
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
                            color: isDark
                                ? Colors.white24
                                : Colors.blueGrey.shade200,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.noCategories,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.blueGrey.shade800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.emptyCategoriesSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () =>
                                _showAdvancedAddCategoryDialog(context),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: widget.categories.length,
                    itemBuilder: (context, index) {
                      final catItem = widget.categories[index];
                      final localizedCategoryName = t.getCategoryName(
                        catItem.key,
                      );
                      final catProducts = widget.products
                          .where(
                            (p) =>
                                p.categoryKey == catItem.key &&
                                p.isToBuy == widget.isBuyScreen,
                          )
                          .toList();

                      final hasProducts = catProducts.isNotEmpty;
                      final activeColor = widget.isBuyScreen
                          ? Colors.red
                          : Colors.green;
                      final subCount = _subcategoryCountOf(
                        catItem,
                        catProducts,
                      );

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
                              _showCategoryActionsSheet(
                                context,
                                catItem,
                                localizedCategoryName,
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
                                            tag:
                                                'category-circle-${catItem.key}',
                                            child: Container(
                                              width: 90,
                                              height: 90,
                                              decoration: BoxDecoration(
                                                color: hasProducts
                                                    ? activeColor.withValues(
                                                        alpha: 0.10,
                                                      )
                                                    : (isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.06,
                                                                )
                                                          : Colors
                                                                .grey
                                                                .shade100),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: hasProducts
                                                      ? activeColor.withValues(
                                                          alpha: 0.35,
                                                        )
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipOval(
                                                child:
                                                    CategoryVisuals.circleChild(
                                                      categoryKey: catItem.key,
                                                      imagePath:
                                                          catItem.imagePath,
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
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: activeColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
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
                                          // Insignia de subcategorÃ­as (Premium Plus): indica
                                          // que al entrar se navega primero por sus
                                          // subcategorÃ­as antes de llegar a los productos.
                                          if (subCount > 0)
                                            Positioned(
                                              left: -2,
                                              bottom: -2,
                                              child: Tooltip(
                                                message: t.subcategories,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors
                                                              .blueGrey
                                                              .shade700
                                                        : Colors
                                                              .blueGrey
                                                              .shade600,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .folder_copy_outlined,
                                                        size: 11,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '$subCount',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                                      color: isDark
                                          ? Colors.grey.shade200
                                          : const Color(0xFF334155),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    itemCount: widget.categories.length,
                    itemBuilder: (context, index) {
                      final catItem = widget.categories[index];
                      final localizedCategoryName = t.getCategoryName(
                        catItem.key,
                      );
                      final catProducts = widget.products
                          .where(
                            (p) =>
                                p.categoryKey == catItem.key &&
                                p.isToBuy == widget.isBuyScreen,
                          )
                          .toList();

                      return _StaggeredItem(
                        index: index,
                        child: ExpandableCategoryCard(
                          catItem: catItem,
                          localizedCategoryName: localizedCategoryName,
                          catProducts: catProducts,
                          isBuyScreen: widget.isBuyScreen,
                          t: t,
                          subcategories: _subcategoriesOf(catItem),
                          isExpanded: _expandedCategoryKey == catItem.key,
                          expandedSubcategory:
                              _expandedCategoryKey == catItem.key
                              ? _expandedSubcategory
                              : null,
                          onToggleExpanded: (want) =>
                              _onToggleExpanded(catItem.key, want),
                          onToggleSubcategory: _onToggleSubcategory,
                          onCardTap: () async {
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
                            _showCategoryActionsSheet(
                              context,
                              catItem,
                              localizedCategoryName,
                            );
                          },
                          onEditProduct: _showEditProductDialog,
                        ),
                      );
                    },
                  ),
            if (_isFabOpen || _isViewFabOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isFabOpen) _toggleFab();
                    if (_isViewFabOpen) _toggleViewFab();
                  },
                ),
              ),
          ],
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
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
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

/// OpciÃ³n del abanico de crear: aparece con fade + slide escalonado segÃºn un
/// retraso por Ã­ndice, imitando el "abanico" de un speed dial.
class _FanOption extends StatefulWidget {
  const _FanOption({
    required this.delay,
    required this.child,
    this.dropDown = false,
  });

  final Duration delay;
  final Widget child;

  /// Cuando es true los botones se deslizan hacia abajo (popup desplegable
  /// debajo del botÃ³n de compartir); si no, hacia arriba (abanico de FABs).
  final bool dropDown;

  @override
  State<_FanOption> createState() => _FanOptionState();
}

class _FanOptionState extends State<_FanOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 0,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.dropDown ? -0.6 : 0.6),
      end: Offset.zero,
    ).animate(curved);
    Future.delayed(widget.delay, () {
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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
