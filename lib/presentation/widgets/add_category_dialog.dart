import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/image_storage.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/add_category.dart';
import '../localization/app_localizations.dart';
import 'dialog_kit.dart';
import 'category_visuals.dart';
import 'show_failure.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late TextEditingController _nameController;
  String? _selectedEmoji;
  String? _imagePath;
  bool _userPicked = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedEmoji = CategoryVisuals.assets.isNotEmpty
        ? CategoryVisuals.assets.first
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Elige automáticamente el PNG de categoría que corresponde al nombre
  /// tecleado (resolviendo la clave canónica con `findNameKey`).
  String? _autoPngFor(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final key = AppLocalizations.findNameKey(text.trim());
    if (key == null) return null;
    return CategoryVisuals.assetFor(key);
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    const accent = DialogAccents.emerald;

if (!_userPicked) {
      final autoPng = _autoPngFor(_nameController.text);
      _selectedEmoji = autoPng ?? CategoryVisuals.assets.first;
    }

    return DialogKit.frame(
      context,
      title: Text(t.addCategory),
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
                label: t.addCategory,
                hint: t.exampleCategoryHint,
              ),
              onChanged: (_) {
                if (_userPicked) return;
                setState(() {});
              },
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
                emoji: _selectedEmoji ?? '📦',
              ),
            ),
            const SizedBox(height: 12),
            DialogKit.assetStrip(
              context: context,
              accent: accent,
              assets: CategoryVisuals.assets,
              selected: _imagePath == null ? _selectedEmoji : null,
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
        DialogKit.cancelButton(context, t.cancel),
        DialogKit.saveButton(
          context,
          t.save,
          accent,
          onPressed: () async {
            final text = _nameController.text.trim();
            if (text.isNotEmpty) {
              final key = AppLocalizations.findNameKey(text) ?? text;
              if (await sl<CategoryRepository>().exists(key)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.categoryAlreadyExists),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              try {
                await sl<AddCategoryUseCase>()(
                  name: key,
                  emoji: _selectedEmoji ?? '📦',
                  imagePath: _imagePath,
                );
                if (context.mounted) {
                  Navigator.pop(context);
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
