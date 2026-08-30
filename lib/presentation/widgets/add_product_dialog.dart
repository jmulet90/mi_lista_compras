import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/image_storage.dart';
import '../../core/utils/product_asset_catalog.dart';
import '../../domain/usecases/add_product.dart';
import '../localization/app_localizations.dart';
import 'dialog_kit.dart';
import 'category_visuals.dart';
import 'premium_limits.dart';
import 'show_failure.dart';

class AddProductDialog extends StatefulWidget {
  final List<String> categories;
  final String? initialCategory;
  final String? initialSubcategory;
  final bool isBuyScreen;

  const AddProductDialog({
    super.key,
    required this.categories,
    this.initialCategory,
    this.initialSubcategory,
    required this.isBuyScreen,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  late TextEditingController _nameController;
  late String _selectedCategory;
  String? _selectedEmoji;
  String? _imagePath;
  String? _subcategory;
  bool _userPicked = false;
  String? _pngFilterCategory;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    /// Siempre usar la primera categoría de la lista pasada.
    /// Si widget.initialCategory viene definido y está en categories, úsalo,
    /// sino toma la primera de la lista para evitar que quede vacío.
    _selectedCategory = widget.categories.isNotEmpty
        ? (widget.initialCategory ?? widget.categories.first)
        : widget.initialCategory ?? '';
    _selectedEmoji = null;
    _subcategory = widget.initialSubcategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    final savedPath = await persistPickedImage(image);
    if (savedPath != null) {
      setState(() {
        _imagePath = savedPath;
        _selectedEmoji = null;
        _userPicked = true;
      });
    }
  }

  /// Busca entre los PNG de la categoría el que corresponda al texto
  /// tecleado (resolviendo sinónimos/plurales vía `findNameKey`).
  String? _autoPngFor(String? text, List<String> pngs) {
    if (text == null || text.trim().isEmpty || pngs.isEmpty) return null;
    final key = AppLocalizations.findNameKey(text.trim()) ?? text.trim();
    final target = key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (target.isEmpty) return null;
    for (final png in pngs) {
      final base = png.substring(png.lastIndexOf('/') + 1);
      final stemText =
          base.endsWith('.png') ? base.substring(0, base.length - 4) : base;
      final stem = stemText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (stem == target) return png;
      if (target.length >= 3 && (stem.startsWith(target) || target.startsWith(stem))) {
        return png;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);

    final catalog = ProductAssetCatalog.instance;
    final ownPngs = catalog.pngsFor(_selectedCategory);
    final filterCats = ownPngs.isNotEmpty
        ? const <String>[]
        : CategoryVisuals.categoryKeys
            .where((k) => catalog.pngsFor(k).isNotEmpty)
            .toList();
    List<String> pngs;
    if (ownPngs.isNotEmpty) {
      pngs = ownPngs;
    } else {
      // Categoría nueva/personalizada: mostrar todo el catálogo por defecto
      // para que el usuario vea todos los productos disponibles; la barra
      // de filtros permite acotar por categoría.
      final effectiveFilter = _pngFilterCategory;
      pngs = effectiveFilter == null
          ? catalog.allPngs()
          : catalog.pngsFor(effectiveFilter);
    }
    if (!_userPicked) {
      _selectedEmoji =
          _autoPngFor(_nameController.text, pngs) ??
              (pngs.isNotEmpty ? pngs.first : null);
    } else if (pngs.isNotEmpty && !pngs.contains(_selectedEmoji)) {
      _selectedEmoji = pngs.first;
    } else if (pngs.isEmpty) {
      _selectedEmoji = null;
    }

    return DialogKit.frame(
      context,
      title: Text(
        _subcategory != null && _subcategory!.isNotEmpty
            ? _subcategory!
            : t.add,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: DialogKit.input(
                context,
                accent,
                label: t.nameLabel,
                hint: t.exampleProductHint,
              ),
              onChanged: (_) {
                if (_userPicked) return;
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            if (widget.categories.isNotEmpty)
              _subcategory != null && _subcategory!.isNotEmpty
                  ? InputDecorator(
                      decoration: DialogKit.input(
                          context, accent, label: t.subcategory),
                      isEmpty: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _subcategory!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DialogKit.isDark(context)
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                initialValue: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: DialogKit.input(context, accent, label: t.categoryLabel),
                items: widget.categories.map((catKey) {
                  return DropdownMenuItem(
                    value: catKey,
                    child: Text(t.getCategoryName(catKey)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                      _userPicked = false;
                      _pngFilterCategory = null;
                      if (widget.initialCategory != null &&
                          val != widget.initialCategory) {
                        _subcategory = null;
                      }
                    });
                  }
                },
              ),
            if (filterCats.isNotEmpty) ...[
              const SizedBox(height: 16),
              _CategoryFilterBar(
                categories: filterCats,
                selected: _pngFilterCategory,
                allLabel: t.all,
                accent: accent,
                onSelect: (key) {
                  setState(() {
                    _pngFilterCategory = key;
                    _userPicked = false;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
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
            Center(
              child: DialogKit.previewCircle(
                accent: accent,
                imagePath: _imagePath,
                emoji: _selectedEmoji,
              ),
            ),
            const SizedBox(height: 12),
            if (pngs.isNotEmpty)
              DialogKit.assetStrip(
                context: context,
                accent: accent,
                assets: pngs,
                selected: _selectedEmoji,
                onSelect: (asset) {
                  setState(() {
                    _selectedEmoji = asset;
                    _imagePath = null;
                    _userPicked = true;
                  });
                },
              ),
            const SizedBox(height: 12),
            DialogKit.mediaRow(
              context,
              cameraLabel: t.camera,
              galleryLabel: t.galleryPicker,
              onCamera: () => _pickImage(ImageSource.camera),
              onGallery: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
      actions: [
        DialogKit.cancelButton(
          context,
          t.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        DialogKit.saveButton(
          context,
          t.save,
          accent,
          onPressed: () async {
            final trimmedName = _nameController.text.trim();
            if (trimmedName.isNotEmpty && _selectedCategory.isNotEmpty) {
              if (!await PremiumLimits.canAddProduct(
                  context, _selectedCategory)) {
                return;
              }
              try {
                await sl<AddProductUseCase>()(
                  name: AppLocalizations.findNameKey(trimmedName) ?? trimmedName,
                  categoryKey: _selectedCategory,
                  isBuyScreen: widget.isBuyScreen,
                  emoji: _selectedEmoji,
                  imagePath: _imagePath,
                  subcategory: _subcategory,
                );

                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } on Failure catch (failure) {
                if (context.mounted) showFailure(context, failure);
              }
            }
          },
        ),
      ],
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.allLabel,
    required this.accent,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final String allLabel;
  final Color accent;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dark = DialogKit.isDark(context);
    return SizedBox(
      height: 38,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _pill(null, allLabel, dark),
            for (final key in categories) ...[
              const SizedBox(width: 8),
              _pill(key, t.getCategoryName(key), dark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String? key, String label, bool dark) {
    final isSelected = selected == key;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onSelect(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : (dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.5)
                : (dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (dark ? Colors.grey.shade100 : accent)
                : (dark ? Colors.grey.shade300 : Colors.blueGrey.shade700),
          ),
        ),
      ),
    );
  }
}