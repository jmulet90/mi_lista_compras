import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/image_storage.dart';
import '../../core/utils/product_asset_catalog.dart';
import '../../domain/usecases/add_product.dart';
import '../localization/app_localizations.dart';
import 'dialog_kit.dart';
import 'premium_limits.dart';
import 'show_failure.dart';

class AddProductDialog extends StatefulWidget {
  final List<String> categories;
  final String? initialCategory;
  final bool isBuyScreen;

  const AddProductDialog({
    super.key,
    required this.categories,
    this.initialCategory,
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
  double? _quantity;
  String? _unit;

  static const List<String> _emojis = ['🥛', '🍞', '🍎', '🍐', '🍊', '🍋', '🍉', '🍇', '🍓', '🫐', '🍒', '🥭','🍍', '🥥', '🥝', '🥑', '🥩', '☕', '🥐', '🧀', '🍌', '🍅', '🧻', '🧼', '🧊'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedCategory = widget.initialCategory ?? (widget.categories.isNotEmpty ? widget.categories.first : '');
    _selectedEmoji = _emojis.first;
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final accent = DialogKit.accentForBuy(widget.isBuyScreen);

    bool categoryExists = widget.categories.contains(_selectedCategory);
    if (!categoryExists && widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }

    final pngs = ProductAssetCatalog.instance.pngsFor(_selectedCategory);
    if (pngs.isNotEmpty && !pngs.contains(_selectedEmoji)) {
      _selectedEmoji = pngs.first;
    } else if (pngs.isEmpty &&
        _selectedEmoji != null &&
        DialogKit.isAssetRef(_selectedEmoji)) {
      _selectedEmoji = _emojis.first;
    }

    return DialogKit.frame(
      context,
      title: Text(t.add),
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
            ),
            const SizedBox(height: 16),
            if (widget.categories.isNotEmpty)
              DropdownButtonFormField<String>(
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
                    });
                  }
                },
              ),
            const SizedBox(height: 16),
            DialogKit.quantityUnitRow(
              context: context,
              accent: accent,
              quantity: _quantity,
              unit: _unit,
              onQuantityChanged: (val) => setState(() => _quantity = val),
              onUnitChanged: (val) => setState(() => _unit = val),
            ),
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
                emoji: _selectedEmoji ?? '🏠',
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
                  });
                },
              )
            else
              DialogKit.emojiStrip(
                context: context,
                accent: accent,
                emojis: _emojis,
                selected: _selectedEmoji,
                onSelect: (emoji) {
                  setState(() {
                    _selectedEmoji = emoji;
                    _imagePath = null;
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
                  quantity: _quantity,
                  unit: _unit,
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
