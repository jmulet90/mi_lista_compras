import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copia la imagen elegida (cámara o galería) a un directorio permanente de
/// la app. image_picker entrega archivos en la caché temporal, que el sistema
/// puede borrar en cualquier momento y dejaría la imagen rota.
Future<String?> persistPickedImage(XFile? image) async {
  if (image == null) return null;
  try {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/custom_images');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final ext = image.path.contains('.')
        ? image.path.split('.').last.toLowerCase()
        : 'jpg';
    final dest =
        '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(image.path).copy(dest);
    return dest;
  } catch (_) {
    return image.path;
  }
}

/// Guarda bytes de imagen (p. ej. descargados de la nube) en el directorio
/// permanente con un nombre fijo, para que sirva de caché local.
Future<String?> persistImageBytes(
  Uint8List bytes, {
  required String name,
}) async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/custom_images');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final dest = '${dir.path}/$name';
    await File(dest).writeAsBytes(bytes, flush: true);
    return dest;
  } catch (_) {
    return null;
  }
}
