import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger();

  void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  void error(String context, Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) debugPrint('[ERROR] $context: $error');
  }
}
