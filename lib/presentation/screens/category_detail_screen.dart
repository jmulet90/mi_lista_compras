import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/image_storage.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/subcategory_item.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/toggle_product.dart';
import '../../domain/usecases/update_product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/subcategory_repository.dart';
import '../app_settings.dart';
import '../localization/app_localizations.dart';
import '../services/main_tab_controller.dart';
import '../services/subcategory_actions.dart';
import '../widgets/action_sheet_menu.dart';
import '../widgets/premium_limits.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/floating_nav_spec.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/category_visuals.dart';
import '../widgets/dialog_kit.dart';
import '../widgets/product_visuals.dart';
import '../../core/utils/product_asset_catalog.dart';
import '../widgets/product_move_animation.dart';
import '../widgets/show_failure.dart';
import '../widgets/subcategory_dialog.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryItem category;
  final bool isBuyScreen;

  /// Si es distinto de null, esta pantalla actúa como el detalle de esa
  /// subcategoría (solo sus productos, sin agrupación) y el encabezado muestra
  /// su visual.
  final String? subcategoryName;
  final SubcategoryItem? subcategoryItem;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.isBuyScreen,
    this.subcategoryName,
    this.subcategoryItem,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with TickerProviderStateMixin {
  final Map<String, GlobalKey> _productRowKeys = {};

  /// Subcategoría expandida en la lista: null (nada), '' ("Sin subcategoría")
  /// o el nombre de una subcategoría.
  String? _expandedSubcategory;

  /// Subcategorías persistidas de esta categoría (clave = categoría en
  /// minúsculas; aquí solo interesa la de [widget.category]).
  Map<String, List<SubcategoryItem>> _subcategories = {};
  StreamSubscription<Map<String, List<SubcategoryItem>>>? _subcategoriesSub;

  /// ¿El abanico del "+" está desplegado?
  bool _isFabOpen = false;
  late final AnimationController _fabAnimationController;

  /// ¿El abanico de vistas (lista/galería) está desplegado?
  bool _isViewFabOpen = false;
  late final AnimationController _viewFabController;
  late final Animation<double> _viewExpandAnimation;

  List<SubcategoryItem> get _subsForCategory =>
      _subcategories[widget.category.key.trim().toLowerCase()] ?? const [];

  /// Modo selección múltiple: marca varios productos para moverlos juntos a
  /// una subcategoría o categoría (opción "Seleccionar" del long press).
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _viewFabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
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
    _fabAnimationController.dispose();
    _viewFabController.dispose();
    super.dispose();
  }

  GlobalKey _rowKeyFor(Product product) =>
      _productRowKeys.putIfAbsent(product.id, () => GlobalKey());

  /// Tag de Hero común para el círculo de una subcategoría. La subcategoría
  /// "Sin subcategoría" se representa con `''` y un sufijo estable.
  String _subHeroTag(String subName) =>
      'subcategory-circle-${widget.category.key}-${subName.isEmpty ? '__none__' : subName.toLowerCase()}';

  /// Subcategoría efectiva del parámetro, normalizando `''` ("Sin
  /// subcategoría") a null para nuevas asignaciones.
  String? _subParam() {
    final name = widget.subcategoryName;
    if (name == null) return null;
    return name.isEmpty ? null : name;
  }

  /// ¿El producto pertenece a la subcategoría activa? Con `''` equivale a
  /// "Sin subcategoría"; con null (no modo sub) todo pertenece.
  bool _productInSub(Product p) {
    final name = widget.subcategoryName;
    if (name == null) return true;
    if (name.isEmpty) return SubcategoryActions.subOf(p) == null;
    return SubcategoryActions.subOf(p) == name;
  }

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
            _showEditProductDialog(context, product);
          },
        ),
        ActionSheetOption(
          icon: Icons.drive_file_move_outline,
          label: t.moveProduct,
          color: const Color(0xFF184878),
          onTap: () {
            Navigator.pop(context);
            SubcategoryActions.promptMoveProduct(
              context,
              product: product,
              categoryKey: widget.category.key,
              subcategories: [for (final s in _subsForCategory) s.name],
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
              context,
              product: product,
              currentCategoryKey: widget.category.key,
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
    final all = await sl<ProductRepository>().getAll();
    final selected = all
        .where((p) =>
            _selectedIds.contains(p.uniqueKey) &&
            p.categoryKey == widget.category.key)
        .toList();
    if (selected.isEmpty) return;
    await SubcategoryActions.promptMoveMany(
      context,
      products: selected,
      categoryKey: widget.category.key,
      subcategories: [for (final s in _subsForCategory) s.name],
      onMoved: () {
        if (mounted) setState(() {});
        _cancelSelection();
      },
    );
  }

  Widget _buildSelectionBar(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.selectedCount(_selectedIds.length),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark
                        ? Colors.grey.shade100
                        : const Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _cancelSelection,
                icon: const Icon(Icons.close),
                label: Text(t.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _selectedIds.isEmpty ? null : _moveSelected,
                icon: const Icon(Icons.drive_file_move_outlined, size: 18),
                label: Text(t.move),
                style: FilledButton.styleFrom(backgroundColor: accent),
              ),
            ],
          ),
        ),
      ),
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
                    onQuantityChanged: (val) =>
                        setDialogState(() => quantity = val),
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

  /// Cambia la pestaña principal (0 = Comprar, 1 = Despensa) y vuelve a la
  /// pantalla principal: desde una categoría o subcategoría, tocar el carrito
  /// o la casita lleva directo a la pantalla principal del lado tocado.
  void _goToMain(int side) {
    MainTabController.switchTo(side);
    Navigator.of(context).popUntil((route) => route.isFirst);
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
                    quantity: qty ?? 0,
                    unit: unit,
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

  /// Abre el diálogo de nuevo producto (dentro de la categoría o de una
  /// subcategoría expandida).
  void _showAddProductDialog(BuildContext context, {String? subcategory}) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        categories: [widget.category.key],
        initialCategory: widget.category.key,
        initialSubcategory: subcategory,
        isBuyScreen: widget.isBuyScreen,
      ),
    );
  }

  /// Crea una subcategoría (Premium Plus; los sin Plus ven el aviso).
  Future<void> _showAddSubcategoryDialog(BuildContext context) async {
    final t = AppLocalizations.of(context);
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
          SubcategoryDialog(categoryKey: widget.category.key, accent: accent),
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

  /// Cambia entre vista lista y galería, con las mismas restricciones que la
  /// pantalla principal (requiere permiso de edición).
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

  /// Opciones del abanico del "+" según el contexto:
  /// - En el detalle de una subcategoría → solo "nuevo producto".
  /// - Nivel de categoría → "nueva subcategoría" + "nuevo producto"
  ///   (subcategoría se oculta si hay una expandida en el acordeón).
  List<Widget> _fabOptions(BuildContext context, AppLocalizations t) {
    final subMode = widget.subcategoryName != null;
    final inSubcategory = subMode || _expandedSubcategory != null;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final options =
        <({String heroTag, IconData icon, String label, VoidCallback onTap})>[];

    if (!inSubcategory) {
      options.add((
        heroTag: 'btn_detail_subcategory',
        icon: Icons.create_new_folder_outlined,
        label: t.newSubcategory,
        onTap: () {
          _toggleFab();
          _showAddSubcategoryDialog(context);
        },
      ));
    }
    options.add((
      heroTag: 'btn_detail_product',
      icon: Icons.add_shopping_cart_rounded,
      label: t.newProduct,
      onTap: () {
        if (!PremiumLimits.checkCanEdit(context)) return;
        _toggleFab();
        _showAddProductDialog(
          context,
          subcategory: subMode
              ? _subParam()
              : (_expandedSubcategory == '' ? null : _expandedSubcategory),
        );
      },
    ));

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

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final t = AppLocalizations.of(context);
    final localizedName = t.getCategoryName(widget.category.key);
    final subMode = widget.subcategoryName != null;
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
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: subMode
                  ? _subHeroTag(widget.subcategoryName!)
                  : 'category-circle-${widget.category.key}',
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
                  child: subMode
                      ? _subVisual(widget.subcategoryItem)
                      : CategoryVisuals.circleChild(
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
                subMode
                    ? (widget.subcategoryName!.isEmpty
                          ? t.noSubcategory
                          : widget.subcategoryName!)
                    : localizedName,
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
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      // El cuerpo reacciona al instante a los cambios del repositorio.
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            StreamBuilder<List<Product>>(
              stream: sl<ProductRepository>().watchAll(),
              builder: (context, snapshot) {
                final uniqueMap = <String, Product>{};
                for (final product in snapshot.data ?? const <Product>[]) {
                  if (product.categoryKey != widget.category.key) continue;
                  if (product.isToBuy != widget.isBuyScreen) continue;
                  uniqueMap['${product.categoryKey}_${product.nameKey.trim().toLowerCase()}_${product.isToBuy}'] =
                      product;
                }
                final currentProducts = uniqueMap.values.toList();
                final visibleProducts = subMode
                    ? currentProducts.where(_productInSub).toList()
                    : currentProducts;

                final subNamesAll =
                    subMode || !PremiumLimits.isPremiumPlusEffectiveSync
                    ? const <String>[]
                    : SubcategoryActions.visibleSubs(visibleProducts);
                final subNames = subNamesAll;

                final showEmpty = subMode
                    ? visibleProducts.isEmpty
                    : visibleProducts.isEmpty && subNames.isEmpty;
                if (showEmpty) {
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
                            color: isDark
                                ? Colors.grey.shade100
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.emptyProductsSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final hasSubGallery = subNames.isNotEmpty;

                if (settings.isGridView && hasSubGallery) {
                  return _buildSubGalleryGrid(
                    context,
                    subNames,
                    visibleProducts,
                    accent: accent,
                    isDark: isDark,
                  );
                }

                return settings.isGridView && visibleProducts.isNotEmpty
                    ? GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          8.0,
                          8.0,
                          8.0,
                          FloatingNavSpec.height +
                              FloatingNavSpec.bottomGap +
                              8.0,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: visibleProducts.length,
                        itemBuilder: (context, index) => _buildGridProduct(
                          context,
                          visibleProducts[index],
                          index,
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          0.0,
                          8.0,
                          0.0,
                          FloatingNavSpec.height +
                              FloatingNavSpec.bottomGap +
                              8.0,
                        ),
                        children: subMode
                            ? [
                                for (final p in visibleProducts)
                                  _buildListProduct(context, p),
                              ]
                            : _buildListChildren(context, visibleProducts),
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
      floatingActionButton: AnimatedBuilder(
        animation: Listenable.merge([_fabAnimationController, _viewFabController]),
        builder: (context, child) {
          if (_selectionMode) return const SizedBox.shrink();
          final t = AppLocalizations.of(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Opciones de vista: crecen pegadas al botón de vistas.
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
                            heroTag: 'btn_detail_view_list',
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
                            heroTag: 'btn_detail_view_gallery',
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
              // Botón de vistas; sube cuando se despliega el abanico de crear.
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: FloatingActionButton(
                  heroTag: 'btn_detail_view',
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
                    if (_isFabOpen) _toggleFab();
                    _toggleViewFab();
                  },
                  child: Transform.rotate(
                    angle: _viewExpandAnimation.value * 0.785398,
                    child: Icon(
                      settings.isGridView
                          ? Icons.grid_view
                          : Icons.view_list,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Abanico de crear: crece pegado al botón principal.
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.bottomCenter,
                child: _isFabOpen
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _fabOptions(context, t),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'btn_detail_main',
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                onPressed: () {
                  if (!PremiumLimits.checkCanEdit(context)) return;
                  _toggleFab();
                },
                child: Transform.rotate(
                  angle: _fabAnimationController.value * 0.785398,
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _selectionMode
          ? _buildSelectionBar(context)
          : StreamBuilder<List<Product>>(
              stream: sl<ProductRepository>().watchAll(),
              builder: (context, snapshot) {
                var buyCount = 0;
                var stockCount = 0;
                for (final p in snapshot.data ?? const <Product>[]) {
                  if (p.categoryKey != widget.category.key) continue;
                  if (p.isToBuy) {
                    buyCount++;
                  } else {
                    stockCount++;
                  }
                }
                return FloatingNavBar(
                  currentIndex: isBuy ? 0 : 1,
                  buyCount: buyCount,
                  stockCount: stockCount,
                  onBuyTap: () => _goToMain(0),
                  onStockTap: () => _goToMain(1),
                );
              },
            ),
    );
  }

  /// Ficha de producto en galería (grid plano o mezclada con fichas de
  /// subcategorías): círculo del producto con gestos de To Buy y borrar.
  Widget _buildGridProduct(BuildContext context, Product product, int index) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);
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
          if (_selectionMode) return false;
          if (direction == DismissDirection.startToEnd) {
            if (!PremiumLimits.checkCanMove(context)) return false;
            final rowRect = rectOfContext(
              _productRowKeys[product.id]?.currentContext,
            );
            await _toggleProduct(product, fromRect: rowRect);
            return false;
          } else {
            if (!PremiumLimits.checkCanEdit(context)) return false;
            bool? delete = await showDialog<bool>(
              context: context,
              builder: (ctx) => DialogKit.frame(
                ctx,
                title: Text(t.delete),
                content: Text(
                  t.deleteProductConfirm(t.getProductName(product.nameKey)),
                ),
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
          color: _isSelected(product)
              ? const Color(0xFF0E7490).withValues(alpha: 0.10)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.62),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _isSelected(product)
                  ? const Color(0xFF0E7490)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.8),
              width: _isSelected(product) ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (!PremiumLimits.checkCanEdit(context)) return;
              if (_selectionMode) {
                _toggleSelection(product);
                return;
              }
              _showQtyUnitDialog(product);
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
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (product.quantity != null)
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
      ),
    );
  }

  /// Galería del nivel de categoría: fichas tocables por subcategoría (y una
  /// "Sin subcategoría" si hay productos sueltos). Sin acordeón, todo a tap.
  Widget _buildSubGalleryGrid(
    BuildContext context,
    List<String> subNames,
    List<Product> visibleProducts, {
    required Color accent,
    required bool isDark,
  }) {
    final ungrouped = visibleProducts
        .where((p) => SubcategoryActions.subOf(p) == null)
        .toList();
    final cells = <Widget>[
      for (final name in subNames)
        _buildSubGalleryTile(
          context,
          name: name,
          item: SubcategoryActions.itemNamed(_subsForCategory, name),
          count: visibleProducts
              .where((p) => SubcategoryActions.subOf(p) == name)
              .length,
          tag: _subHeroTag(name),
          accent: accent,
          isDark: isDark,
          onTap: () => _pushSubDetails(name),
        ),
      // Los productos sin subcategoría se muestran directamente, mezclados
      // con las fichas de subcategorías (sin carpeta "Sin subcategoría").
      for (var i = 0; i < ungrouped.length; i++)
        _buildGridProduct(context, ungrouped[i], i),
    ];
    return GridView.builder(
      key: const ValueKey('grid-subs'),
      padding: EdgeInsets.fromLTRB(
        12.0,
        12.0,
        12.0,
        FloatingNavSpec.height + FloatingNavSpec.bottomGap + 8.0,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.82,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) => cells[index],
    );
  }

  Widget _buildSubGalleryTile(
    BuildContext context, {
    required String name,
    required SubcategoryItem? item,
    required int count,
    required String tag,
    required Color accent,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final t = AppLocalizations.of(context);
    final label = name.isEmpty ? t.noSubcategory : name;
    return Card(
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
        onTap: onTap,
        onLongPress: name.isEmpty
            ? null
            : () {
                if (!PremiumLimits.checkCanEdit(context)) return;
                SubcategoryActions.showMenu(
                  context,
                  categoryKey: widget.category.key,
                  sub: name,
                  accent: accent,
                  onRenamed: () {
                    if (mounted) setState(() {});
                  },
                  onDeleted: () {
                    if (mounted) setState(() {});
                  },
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
                        tag: tag,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: count > 0
                                ? accent.withValues(alpha: 0.10)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.grey.shade100),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: count > 0
                                  ? accent.withValues(alpha: 0.35)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _subVisual(item, emojiSize: 48),
                          ),
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '$count',
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
                label,
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
    );
  }

  Future<void> _pushSubDetails(String name) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          category: widget.category,
          isBuyScreen: widget.isBuyScreen,
          subcategoryName: name.isEmpty ? '' : name,
          subcategoryItem: name.isEmpty
              ? null
              : SubcategoryActions.itemNamed(_subsForCategory, name),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Visual de una subcategoría: foto del usuario > carpeta por defecto.
  Widget _subVisual(SubcategoryItem? item, {double emojiSize = 22}) {
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);
    final defaultsToFolder = item == null || item.imagePath == null;
    if (defaultsToFolder) {
      return Center(
        child: Icon(
          Icons.folder_open_rounded,
          size: emojiSize + 6,
          color: accent,
        ),
      );
    }
    return ProductVisuals.circleChild(
      imagePath: item.imagePath,
      emoji: null,
      emojiSize: emojiSize,
    );
  }

  /// Contenido de la lista según subcategorías (Premium Plus):
  /// - Sin subcategorías → productos directamente.
  /// - Con subcategorías → filas plegables por subcategoría con contador, más
  ///   una fila "Sin subcategoría" si hay productos sin asignar.
  List<Widget> _buildListChildren(
    BuildContext context,
    List<Product> products,
  ) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);

    final plus = PremiumLimits.isPremiumPlusEffectiveSync;
    final subs = SubcategoryActions.visibleSubs(products);
    if (!plus || subs.isEmpty) {
      return [for (final p in products) _buildListProduct(context, p)];
    }

    final children = <Widget>[];
    void tile(Product p) => children.add(_buildListProduct(context, p));

    for (final sub in subs) {
      final items = products
          .where((p) => SubcategoryActions.subOf(p) == sub)
          .toList();
      final isOpen = _expandedSubcategory == sub;
      children.add(
        _subRow(context, sub, items.length, isOpen, t, isDark, accent),
      );
      if (isOpen) items.forEach(tile);
    }
    // Los productos sin subcategoría se muestran directamente, mezclados
    // con las filas de subcategorías (sin carpeta "Sin subcategoría").
    SubcategoryActions.ungrouped(products).forEach(tile);
    return children;
  }

  Widget _subRow(
    BuildContext context,
    String? sub,
    int count,
    bool isOpen,
    AppLocalizations t,
    bool isDark,
    Color accent,
  ) {
    final label = sub ?? t.noSubcategory;
    final item = sub == null
        ? null
        : SubcategoryActions.itemNamed(_subsForCategory, sub);
    final defaultsToFolder = item == null || item.imagePath == null;
    final hasItems = count > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Card(
        margin: EdgeInsets.zero,
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
        child: InkWell(
          onTap: sub == null
              ? () {
                  setState(() {
                    _expandedSubcategory = isOpen ? null : '';
                  });
                }
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryDetailScreen(
                        category: widget.category,
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
                  categoryKey: widget.category.key,
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
                      'subcategory-circle-${widget.category.key}-${(sub ?? '').toLowerCase()}',
                  child: Container(
                    width: 56,
                    height: 56,
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
                                size: 28,
                                color: accent,
                              ),
                            )
                          : ProductVisuals.circleChild(
                              imagePath: item.imagePath,
                              emoji: null,
                              emojiSize: 30,
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
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
                          color: hasItems
                              ? accent.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count ${t.productsCount}',
                          style: TextStyle(
                            color: hasItems
                                ? accent
                                : (isDark ? Colors.grey.shade500 : Colors.grey),
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
                    size: 22,
                    color: isDark ? Colors.grey.shade400 : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedSubcategory = isOpen ? null : (sub ?? '');
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListProduct(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      elevation: 0,
      color: _isSelected(product)
          ? const Color(0xFF0E7490).withValues(alpha: 0.10)
          : isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.62),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _isSelected(product)
              ? const Color(0xFF0E7490)
              : isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.8),
          width: _isSelected(product) ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: Key('detail_${product.id}'),
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
              _productRowKeys[product.id]?.currentContext,
            );
            await _toggleProduct(product, fromRect: rowRect);
            return false;
          } else {
            if (!PremiumLimits.checkCanEdit(context)) return false;
            bool? delete = await showDialog<bool>(
              context: context,
              builder: (ctx) => DialogKit.frame(
                ctx,
                title: Text(t.delete),
                content: Text(
                  t.deleteProductConfirm(t.getProductName(product.nameKey)),
                ),
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
            onTap: () {
              if (!PremiumLimits.checkCanEdit(context)) return;
              if (_selectionMode) {
                _toggleSelection(product);
                return;
              }
              _showQtyUnitDialog(product);
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
                        color: isDark
                            ? Colors.grey.shade100
                            : const Color(0xFF0F172A),
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

class _FanOption extends StatefulWidget {
  const _FanOption({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

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
      begin: const Offset(0, 0.6),
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
