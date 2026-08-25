import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/bootstrap.dart';
import 'core/crash_overlay.dart';
import 'core/logger.dart';
import 'presentation/app/mi_lista_compras_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  CrashOverlay.init();
  CrashOverlay.log('App starting at ${DateTime.now()}');
  CrashOverlay.log('Platform: ${defaultTargetPlatform.name}');
  CrashOverlay.log('kDebugMode=$kDebugMode, kReleaseMode=$kReleaseMode');
  CrashOverlay.log('OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');

  runZonedGuarded(() async {
    try {
      CrashOverlay.log('Calling bootstrap()...');
      await bootstrap();
      CrashOverlay.log('bootstrap() completed OK');
    } catch (e, st) {
      CrashOverlay.logError('FATAL bootstrap error', e, st);
      const AppLogger().error('Error fatal en bootstrap', e, st);
    }

    CrashOverlay.log('Calling runApp()...');
    runApp(const MiListaComprasApp());
  }, (error, stack) {
    CrashOverlay.logError('Uncaught zone error', error, stack);
  });
}
