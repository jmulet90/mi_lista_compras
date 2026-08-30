import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/category_item.dart';
import '../../domain/entities/product.dart';
import '../localization/app_localizations.dart';

/// Una sección de la lista (una categoría) en el export.
class ShareSection {
  final String title;
  final List<ShareItem> items;

  const ShareSection({required this.title, required this.items});
}

/// Un producto dentro de una sección: nombre, imagen del catálogo (asset)
/// y metadatos (cantidad/unidad).
class ShareItem {
  final String name;
  final String? assetPath;
  final String meta;

  const ShareItem({required this.name, this.assetPath, this.meta = ''});
}

/// Exporta la lista de Comprar a PDF o imagen (JPG) y abre el diálogo de
/// compartir del sistema.
class ShoppingListExporter {
  ShoppingListExporter._();

  static Future<void> exportAsPdf({
    required BuildContext context,
    required List<Product> products,
    required List<CategoryItem> categories,
  }) async {
    final t = AppLocalizations.of(context);
    final sections = _sections(products: products, categories: categories, t: t);
    if (sections.isEmpty) {
      _snack(context, t.exportListEmpty);
      return;
    }
    if (!context.mounted) return;
    _snack(context, t.exporting, duration: const Duration(milliseconds: 900));
    try {
      final date = _dateLabel();
      final bytes = await _pdfFromPng(await _renderCardPng(
        sections: sections,
        t: t,
        date: date,
      ));
      if (!context.mounted) return;
      await _shareBytes(
        bytes: bytes,
        filename: 'lista_compras_${_fileStamp()}.pdf',
        mimeType: 'application/pdf',
        title: t.shoppingList,
      );
    } catch (e, st) {
      debugPrint('[Export] pdf falló: $e\n$st');
      _snack(context, t.exportFailed);
    }
  }

  static Future<void> exportAsImage({
    required BuildContext context,
    required List<Product> products,
    required List<CategoryItem> categories,
  }) async {
    final t = AppLocalizations.of(context);
    final sections = _sections(products: products, categories: categories, t: t);
    if (sections.isEmpty) {
      _snack(context, t.exportListEmpty);
      return;
    }
    if (!context.mounted) return;
    _snack(context, t.exporting, duration: const Duration(milliseconds: 900));
    try {
      final date = _dateLabel();
      final bytes = _toJpgOrPng(
        (await _renderCardPng(
          sections: sections,
          t: t,
          date: date,
        )).$1,
      );
      if (!context.mounted) return;
      await _shareBytes(
        bytes: bytes,
        filename: 'lista_compras_${_fileStamp()}.jpg',
        mimeType: 'image/jpeg',
        title: t.shoppingList,
      );
    } catch (e, st) {
      debugPrint('[Export] imagen falló: $e\n$st');
      _snack(context, t.exportFailed);
    }
  }

  static List<ShareSection> _sections({
    required List<Product> products,
    required List<CategoryItem> categories,
    required AppLocalizations t,
  }) {
    final result = <ShareSection>[];
    for (final cat in categories) {
      final items = products
          .where((p) => p.categoryKey == cat.key && p.isToBuy)
          .toList();
      if (items.isEmpty) continue;
      result.add(
        ShareSection(
          title: t.getCategoryName(cat.key),
          items: [
            for (final p in items)
              ShareItem(
                name: p.nameKey.trim(),
                assetPath: (p.emoji?.startsWith('assets/') ?? false) ? p.emoji : null,
                meta: _meta(p),
              ),
          ],
        ),
      );
    }
    return result;
  }

  static String _meta(Product p) {
    final q = p.quantity;
    if (q == null) return '';
    final qty = q == q.roundToDouble() ? q.toInt().toString() : q.toString();
    final unit = (p.unit?.trim().isNotEmpty ?? false) ? p.unit!.trim() : 'un';
    return '× $qty $unit';
  }

  static String _dateLabel() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$d/$m/${now.year}';
  }

  static String _fileStamp() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}$m$d';
  }

  /// Convierte la tarjeta renderizada (PNG) en un PDF de una página,
  /// escalando la imagen con el mismo aspecto que el JPG: idéntico diseño,
  /// tamaños de letra y PNGs de producto.
  static Future<Uint8List> _pdfFromPng(
    (Uint8List, int, int) render,
  ) async {
    final pngBytes = render.$1;
    final widthPx = render.$2;
    final heightPx = render.$3;
    final page = PdfPageFormat.a4;
    const margin = 16.0;
    final maxW = page.width - margin * 2;
    final maxH = page.height - margin * 2;
    final fitW = maxW / widthPx;
    final fitH = maxH / heightPx;
    final fit = fitW < fitH ? fitW : fitH;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: page,
        build: (_) => pw.Center(
          child: pw.Image(
            pw.MemoryImage(pngBytes),
            width: widthPx * fit,
            height: heightPx * fit,
          ),
        ),
      ),
    );
    return doc.save();
  }

  /// Renderiza la tarjeta (la misma que se usa para el JPG) y devuelve sus
  /// bytes PNG junto con el ancho y alto en píxeles.
  static Future<(Uint8List, int, int)> _renderCardPng({
    required List<ShareSection> sections,
    required AppLocalizations t,
    required String date,
  }) async {
    final (image, widthPx, heightPx) = await _renderCard(
      sections: sections,
      t: t,
      date: date,
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) throw StateError('png encode failed');
    return (png.buffer.asUint8List(), widthPx, heightPx);
  }

  /// Dibuja la tarjeta directamente con Canvas/TextPainter (sin widgets ni
  /// Overlay), determinista en todos los dispositivos.
  static Future<(ui.Image, int, int)> _renderCard({
    required List<ShareSection> sections,
    required AppLocalizations t,
    required String date,
  }) async {
    const logWidth = 380.0;
    const hPad = 24.0;
    const headerH = 116.0;
    const navy = Color(0xFF184878);
    const amber = Color(0xFFC27A22);
    const slate = Color(0xFF3A4657);
    const white = Colors.white;
    const creamText = Color(0xFFF5C66B);
    const blueSoft = Color(0xFFBBD2EA);

    // Escala dinámica: los GPUs recortan la textura si se supera un tope
    // (en el Realme se cortaba). Se calcula con una cota superior de la
    // altura real para que la imagen nunca quede recortada.
    const budgetPx = 2000;
    final estHeight = _estimateHeight(sections);
    var scale = 2.0;
    if (estHeight * scale > budgetPx) {
      scale = budgetPx / estHeight;
      if (scale < 0.6) scale = 0.6;
    }

    final painter = ui.PictureRecorder();
    final canvas = Canvas(painter);
    canvas.scale(scale);

    // Prepara las imágenes del catálogo una sola vez.
    final images = <String, ui.Image?>{};
    for (final section in sections) {
      for (final item in section.items) {
        final asset = item.assetPath;
        if (asset == null || images.containsKey(asset)) continue;
        images[asset] = await _loadUiImage(asset);
      }
    }

    // Fondo crema.
    canvas.drawRect(Rect.fromLTWH(0, 0, logWidth, 40000), Paint()..color = const Color(0xFFFDFBF5));

    // Cabecera naval.
    canvas.drawRect(Rect.fromLTWH(0, 0, logWidth, headerH), Paint()..color = navy);
    var hy = 20.0;
    hy += _text(canvas, t.appName, x: hPad, y: hy, fontSize: 13, color: creamText, weight: FontWeight.w700);
    hy += 6;
    hy += _text(canvas, t.shoppingList, x: hPad, y: hy, fontSize: 22, color: white, weight: FontWeight.w800);
    hy += 3;
    hy += _text(canvas, date, x: hPad, y: hy, fontSize: 12, color: blueSoft, weight: FontWeight.w400);

    var y = headerH + 20.0;
    const iconW = 22.0;
    for (final section in sections) {
      // Título de sección: barra ámbar + texto.
      const barY = 1.0;
      final bar = RRect.fromRectAndRadius(Rect.fromLTWH(hPad, y + barY, 5, 16), const Radius.circular(3));
      canvas.drawRRect(bar, Paint()..color = amber);
      final textX = hPad + 13.0;
      final titleH = _text(canvas, section.title, x: textX, y: y, fontSize: 16, color: navy, weight: FontWeight.w800, maxWidth: logWidth - textX - hPad);
      y += titleH + 8;

      for (final item in section.items) {
        // Imagen del catálogo (PNG) a la izquierda del nombre.
        final assetImage = item.assetPath == null ? null : images[item.assetPath];
        final nameX = assetImage == null
            ? textX
            : hPad + iconW + 8;
        final iconX = hPad;

        // Meta a la derecha (cantidad/unidad), nombre a la izquierda.
        final metaPainter = TextPainter(
          text: TextSpan(
            text: item.meta,
            style: const TextStyle(color: navy, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final metaW = item.meta.isEmpty ? 0.0 : metaPainter.width;
        final metaX = logWidth - hPad - metaW;
        final nameMaxW = metaX - nameX - 12;
        final nameH = _text(
          canvas,
          item.name,
          x: nameX,
          y: y + (iconW - 17) / 2,
          fontSize: 14,
          color: slate,
          weight: FontWeight.w400,
          maxWidth: nameMaxW.clamp(10, 9999),
        );
        if (assetImage != null) {
          canvas.drawImageRect(
            assetImage,
            Rect.fromLTWH(0, 0, assetImage.width.toDouble(), assetImage.height.toDouble()),
            Rect.fromLTWH(iconX, y, iconW, iconW),
            Paint(),
          );
        }
        if (item.meta.isNotEmpty) {
          metaPainter.paint(canvas, Offset(metaX, y));
        }
        y += _max3(nameH, metaPainter.height, iconW) + 10;
      }
      y += 10;
    }

    final picture = painter.endRecording();
    final widthPx = (logWidth * scale).round();
    final heightPx = (estHeight * scale).floor();
    final image = await picture.toImage(widthPx, heightPx);
    return (image, widthPx, heightPx);
  }

  /// Cota superior de la altura real dibujada (para elegir la escala sin
  /// recortes). Coincide o supera ligeramente la altura final del canvas.
  static double _estimateHeight(List<ShareSection> sections) {
    var y = 116.0 + 20.0;
    for (final section in sections) {
      y += 24 + 8; // título de sección (alto máximo) + margen
      y += section.items.length * 34; // fila: icono/texto + espaciado (máximo)
      y += 10;
    }
    return y + 20;
  }

  static Future<ui.Image?> _loadUiImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('[Export] no se pudo cargar $assetPath: $e');
      return null;
    }
  }

  static double _text(
    Canvas canvas,
    String text, {
    required double x,
    required double y,
    required double fontSize,
    required Color color,
    required FontWeight weight,
    double maxWidth = double.infinity,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, Offset(x, y));
    return tp.height;
  }

  static double _max3(double a, double b, double c) => a > b ? (a > c ? a : c) : (b > c ? b : c);

  /// Devuelve JPG por defecto; si la conversión fallara, entrega PNG
  /// para que la exportación nunca se quede sin archivo.
  static Uint8List _toJpgOrPng(Uint8List pngBytes) {
    try {
      final decoded = img.decodePng(pngBytes);
      if (decoded != null) return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
      debugPrint('[Export] decodePng devolvió null, enviando PNG');
    } on Exception catch (e) {
      debugPrint('[Export] encodeJpg falló ($e), enviando PNG');
    }
    return pngBytes;
  }

  static Future<void> _shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    required String title,
  }) async {
    await Share.shareXFiles(
      [
        XFile.fromData(bytes, mimeType: mimeType, name: filename),
      ],
      subject: title,
      text: title,
    );
  }

  static void _snack(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration ?? const Duration(seconds: 2),
        ),
      );
  }
}