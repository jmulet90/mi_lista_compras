import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/failures.dart';
import '../../core/utils/image_storage.dart';
import '../../domain/entities/subcategory_item.dart';
import '../localization/app_localizations.dart';
import '../services/subcategory_actions.dart';
import 'dialog_kit.dart';
import 'show_failure.dart';

/// Diálogo de nueva subcategoría (Premium Plus): nombre, círculo de vista
/// previa y cámara/galería (foto opcional).
/// Persiste la subcategoría y devuelve su nombre al cerrar con éxito.
class SubcategoryDialog extends StatefulWidget {
  final String categoryKey;
  final Color accent;

  const SubcategoryDialog({
    super.key,
    required this.categoryKey,
    required this.accent,
  });

  @override
  State<SubcategoryDialog> createState() => _SubcategoryDialogState();
}

class _SubcategoryDialogState extends State<SubcategoryDialog> {
  late TextEditingController _nameController;
  String? _imagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final accent = widget.accent;

    return DialogKit.frame(
      context,
      title: Text(t.newSubcategory),
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
                label: t.subcategory,
                hint: t.subcategoryHint,
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
                emptyIcon: Icons.folder_open_rounded,
              ),
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
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            final messenger = ScaffoldMessenger.of(context);
            try {
              await SubcategoryActions.create(
                widget.categoryKey,
                SubcategoryItem(
                  name: name,
                  imagePath: _imagePath,
                ),
              );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(t.subcategoryCreated(name)),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              if (context.mounted) {
                Navigator.pop(context, name);
              }
            } on Failure catch (failure) {
              if (context.mounted) {
                Navigator.pop(context);
              }
              showFailureMessage(messenger, failure);
            }
          },
        ),
      ],
    );
  }
}