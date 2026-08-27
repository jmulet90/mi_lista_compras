import 'dart:io';

import 'package:flutter/material.dart';

/// Paleta compartida con las pantallas principales y el menú.
class DialogAccents {
  static const rose = Color(0xFFE11D48);
  static const emerald = Color(0xFF059669);
  static const ink = Color(0xFF0F172A);
}

/// Kit de piezas para los diálogos de crear/editar, alineado con el
/// estilo "vidrio" de la pantalla principal.
class DialogKit {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Acento según la pantalla desde la que se abre el diálogo.
  static Color accentForBuy(bool isBuy) =>
      isBuy ? DialogAccents.rose : DialogAccents.emerald;

  /// Estructura base del diálogo: esquinas grandes, borde sutil y
  /// tipografía del título consistente con la app.
  static AlertDialog frame(
    BuildContext context, {
    required Widget title,
    required Widget content,
    required List<Widget> actions,
  }) {
    final dark = isDark(context);
    return AlertDialog(
      backgroundColor:
          dark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.97),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.85),
        ),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: dark ? Colors.grey.shade100 : DialogAccents.ink,
      ),
      title: title,
      content: content,
      actions: actions,
    );
  }

  /// Campos de texto redondeados con relleno suave y foco del acento.
  static InputDecoration input(
    BuildContext context,
    Color accent, {
    String? label,
    String? hint,
  }) {
    final dark = isDark(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: dark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF1F5F9),
      enabledBorder: border(dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.grey.shade300),
      focusedBorder: border(accent.withValues(alpha: 0.6), 1.6),
    );
  }

  /// Círculo de vista previa (foto, PNG del catálogo o ícono por defecto) con anillo.
  static Widget previewCircle({
    required Color accent,
    String? imagePath,
    String? emoji,
  }) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imagePath != null
            ? Image.file(File(imagePath), fit: BoxFit.cover)
            : isAssetRef(emoji)
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(emoji!, fit: BoxFit.contain),
                  )
                : Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 26,
                      color: accent.withValues(alpha: 0.5),
                    ),
                  ),
      ),
    );
  }

  /// ¿El valor guarda una referencia a un asset (y no un glifo emoji)?
  static bool isAssetRef(String? value) =>
      value != null && value.startsWith('assets/');

  /// Franja horizontal de emojis seleccionables.
  static Widget emojiStrip({
    required BuildContext context,
    required Color accent,
    required List<String> emojis,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    final dark = isDark(context);
    return SizedBox(
      width: double.maxFinite,
      height: 62,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          final emoji = emojis[index];
          final isSelected = selected == emoji;
          return Padding(
            padding: const EdgeInsets.all(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelect(emoji),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: 0.12)
                      : (dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? accent.withValues(alpha: 0.45)
                        : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Botones Cámara / Galería en píldora.
  static Widget mediaRow(
    BuildContext context, {
    required String cameraLabel,
    required String galleryLabel,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    final dark = isDark(context);
    OutlinedButton pill(String label, IconData icon, VoidCallback onPressed) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              dark ? Colors.grey.shade300 : const Color(0xFF334155),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.grey.shade300,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        pill(cameraLabel, Icons.camera_alt, onCamera),
        pill(galleryLabel, Icons.image, onGallery),
      ],
    );
  }

  /// Botón Cancelar discreto.
  static Widget cancelButton(
    BuildContext context,
    String label, {
    VoidCallback? onPressed,
  }) {
    final dark = isDark(context);
    return TextButton(
      onPressed: onPressed ?? () => Navigator.pop(context),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  /// Botón Guardar en píldora con el acento del contexto.
  static Widget saveButton(
    BuildContext context,
    String label,
    Color accent, {
    required VoidCallback? onPressed,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  /// Franja horizontal de PNG del catálogo por categoría, seleccionables.
  static Widget assetStrip({
    required BuildContext context,
    required Color accent,
    required List<String> assets,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    final dark = isDark(context);
    return SizedBox(
      width: double.maxFinite,
      height: 62,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          final isSelected = selected == asset;
          return Padding(
            padding: const EdgeInsets.all(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelect(asset),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: 0.12)
                      : (dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? accent.withValues(alpha: 0.45)
                        : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSelected ? 5 : 3),
                  child: Image.asset(asset, fit: BoxFit.contain),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static const List<String> unitOptions = [
    'un', 'kg', 'g', 'L', 'ml', 'pza', 'paq', 'cja', 'dzn', 'lta', 'bsa',
  ];

  static double stepForUnit(String? unit) {
    if (unit == 'kg' || unit == 'g' || unit == 'L' || unit == 'ml') return 0.5;
    return 1.0;
  }

  static String formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  static Widget quantityUnitRow({
    required BuildContext context,
    required Color accent,
    required double? quantity,
    required String? unit,
    required ValueChanged<double?> onQuantityChanged,
    required ValueChanged<String?> onUnitChanged,
  }) {
    final dark = isDark(context);
    final subColor = dark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: TextEditingController(
              text: quantity != null ? formatQuantity(quantity) : '',
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              onQuantityChanged(parsed);
            },
            decoration: InputDecoration(
              labelText: 'Cantidad',
              labelStyle: TextStyle(color: subColor, fontSize: 13),
              hintText: '1',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
              suffixIcon: quantity != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          icon: Icon(Icons.remove_circle_outline, color: accent),
                          onPressed: () {
                            final step = stepForUnit(unit);
                            final next = quantity - step;
                            onQuantityChanged(next > 0 ? next : null);
                          },
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          icon: Icon(Icons.add_circle_outline, color: accent),
                          onPressed: () {
                            final step = stepForUnit(unit);
                            onQuantityChanged(quantity + step);
                          },
                        ),
                      ],
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      icon: Icon(Icons.add_circle_outline, color: accent),
                      onPressed: () {
                        final step = stepForUnit(unit);
                        onQuantityChanged(step);
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: unit,
              isDense: true,
              isExpanded: true,
              hint: Text('Unidad', style: TextStyle(color: subColor, fontSize: 13)),
              style: TextStyle(
                fontSize: 14,
                color: dark ? Colors.grey.shade200 : const Color(0xFF0F172A),
              ),
              items: unitOptions.map((u) {
                return DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: onUnitChanged,
            ),
          ),
        ),
      ],
    );
  }
}
