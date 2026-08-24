import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/usecases/add_category.dart';
import '../localization/app_localizations.dart';
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
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _selectedEmoji = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.addCategory),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.addCategory,
                hintText: t.exampleCategoryHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(t.visualCustomization, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
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
                  child: _imagePath != null
                      ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                      : Center(
                    child: Text(
                      _selectedEmoji ?? '📦',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.maxFinite,
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  final isSelected = _selectedEmoji == emoji && _imagePath == null;

                  return SizedBox(
                    width: 65,
                    height: 65,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          setState(() {
                            _selectedEmoji = emoji;
                            _imagePath = null;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
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
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(t.camera),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image, size: 18),
                  label: Text(t.galleryPicker),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        ElevatedButton(
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
          child: Text(t.save),
        ),
      ],
    );
  }
}
