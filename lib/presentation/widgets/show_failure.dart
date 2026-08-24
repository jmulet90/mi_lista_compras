import 'package:flutter/material.dart';

import '../../core/failures.dart';
import '../localization/app_localizations.dart';

/// Muestra un SnackBar con el mensaje de un [Failure] (o genérico).
void showFailure(BuildContext context, Object error) {
  final message =
      error is Failure ? error.message : AppLocalizations.of(context).unexpectedError;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red),
  );
}

/// Variante segura para usar tras awaits: captura el messenger antes del hueco asíncrono.
void showFailureMessage(ScaffoldMessengerState messenger, Object error,
    {String fallbackError = 'Ocurrió un error inesperado'}) {
  final message = error is Failure ? error.message : fallbackError;
  messenger.showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red),
  );
}
