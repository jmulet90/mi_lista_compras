import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/image_storage.dart';
import '../../domain/usecases/add_category.dart';
import '../localization/app_localizations.dart';
import 'dialog_kit.dart';
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

  static const List<String> _emojis = ['🍲', '🥩', '☕', '🥐', '🧀', '🍞', '🥞', '🥓',  '🍎', '🍌', '🥦', '🥔','🥂', '🍷', '🍺', '🧃', '🥛', '☕', '🫖', '🧽', '✨', '🧼', '🧻', '🧹', '🧺',  '📦', '🛒', '🏠', '💡', '🐾', '💊', '🍼', '🔋'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
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
    const accent = DialogAccents.emerald;

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
        DialogKit.cancelButton(context, t.cancel),
        DialogKit.saveButton(
          context,
          t.save,
          accent,
          onPressed: () async {
            if (_nameController.text.trim().isNotEmpty) {
              try {
                await sl<AddCategoryUseCase>()(
                  name: AppLocalizations.findNameKey(_nameController.text.trim()) ??
                      _nameController.text.trim(),
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
