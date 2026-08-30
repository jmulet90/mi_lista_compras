import 'package:flutter/material.dart';

import '../../core/failures.dart';
import '../../domain/entities/subcategory_item.dart';
import '../localization/app_localizations.dart';
import '../services/subcategory_actions.dart';
import 'dialog_kit.dart';
import 'show_failure.dart';

/// Selector de subcategoría para los diálogos de producto (Premium Plus).
///
/// Muestra las subcategorías existentes de la categoría más las creadas en
/// la sesión; cada opción se puede combinar con un botón "＋" que crea una
/// nueva subcategoría al momento.
class SubcategorySelector extends StatefulWidget {
  final String categoryKey;
  final List<String> existing;
  final String? value;
  final Color accent;
  final ValueChanged<String?> onChanged;

  const SubcategorySelector({
    super.key,
    required this.categoryKey,
    required this.existing,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<SubcategorySelector> createState() => _SubcategorySelectorState();
}

class _SubcategorySelectorState extends State<SubcategorySelector> {
  final Set<String> _session = {};

  List<String> get _options {
    final merged = <String>{...widget.existing, ..._session};
    final list = merged.toList()..sort();
    return list;
  }

  Future<void> _create() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogKit.frame(
        ctx,
        title: Text(t.newSubcategory),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: DialogKit.input(
            ctx,
            widget.accent,
            label: t.subcategory,
            hint: t.subcategoryHint,
          ),
        ),
        actions: [
          DialogKit.cancelButton(ctx, t.cancel),
          DialogKit.saveButton(
            ctx,
            t.save,
            widget.accent,
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        await SubcategoryActions.create(
          widget.categoryKey,
          SubcategoryItem(name: name),
        );
      } on Failure catch (failure) {
        if (context.mounted) showFailureMessage(messenger, failure);
        return;
      }
      if (!context.mounted) return;
      setState(() => _session.add(name));
      widget.onChanged(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final current = widget.value ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: current,
            decoration: DialogKit.input(context, widget.accent, label: t.subcategory),
            items: [
              DropdownMenuItem(value: '', child: Text(t.noSubcategory)),
              for (final sub in _options)
                DropdownMenuItem(value: sub, child: Text(sub)),
            ],
            onChanged: (val) => widget.onChanged((val ?? '').isEmpty ? null : val),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: IconButton.filledTonal(
            onPressed: _create,
            icon: const Icon(Icons.create_new_folder_outlined, size: 20),
            color: widget.accent,
            tooltip: t.newSubcategory,
          ),
        ),
      ],
    );
  }
}