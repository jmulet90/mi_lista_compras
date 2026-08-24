import 'package:flutter/material.dart';

import 'core/bootstrap.dart';
import 'presentation/app/mi_lista_compras_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await bootstrap();

  runApp(const MiListaComprasApp());
}
