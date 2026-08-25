import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CrashOverlay {
  CrashOverlay._();

  static final CrashOverlay instance = CrashOverlay._();
  static final List<String> _logs = [];
  static OverlayEntry? _overlayEntry;
  static bool _showing = false;

  static List<String> get logs => List.unmodifiable(_logs);

  static void init() {
    _log('CrashOverlay initialized');
    _log('kDebugMode=$kDebugMode, kReleaseMode=$kReleaseMode');

    FlutterError.onError = (details) {
      final msg = 'FlutterError: ${details.exceptionAsString()}\n'
          '${details.stack ?? "(no stack)"}';
      _log(msg);
      dev.log(msg, name: 'CrashOverlay');

      if (kReleaseMode && !_showing) {
        _showOverlay();
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final msg = 'PlatformDispatcher error: $error\n$stack';
      _log(msg);
      dev.log(msg, name: 'CrashOverlay');

      if (kReleaseMode && !_showing) {
        _showOverlay();
      }
      return true;
    };

    runZonedGuarded(() {}, (error, stack) {
      final msg = 'Zone error: $error\n$stack';
      _log(msg);
      dev.log(msg, name: 'CrashOverlay');

      if (kReleaseMode && !_showing) {
        _showOverlay();
      }
    });
  }

  static void log(String message) {
    _log(message);
    dev.log(message, name: 'CrashOverlay');
  }

  static void logError(String context, Object error, [StackTrace? stack]) {
    final msg = '[$context] $error\n${stack ?? "(no stack)"}';
    _log(msg);
    dev.log(msg, name: 'CrashOverlay');
  }

  static void _log(String message) {
    final timestamped = '[${DateTime.now()}] $message';
    _logs.add(timestamped);
    if (_logs.length > 200) _logs.removeAt(0);
  }

  static void _showOverlay() {
    if (_showing) return;
    _showing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = WidgetsBinding.instance.rootElement;
      if (overlay == null) return;

      _overlayEntry = OverlayEntry(
        builder: (_) => _CrashOverlayWidget(
          onDismiss: () {
            _overlayEntry?.remove();
            _overlayEntry = null;
            _showing = false;
          },
        ),
      );

      Overlay.of(overlay).insert(_overlayEntry!);
    });
  }

  static void showManually(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CrashOverlayWidget(
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _CrashOverlayWidget extends StatelessWidget {
  final VoidCallback onDismiss;

  const _CrashOverlayWidget({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final allLogs = CrashOverlay.logs;

    return Material(
      color: const Color(0xE61A1A2E),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.redAccent, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Diagnostico de Errores',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: allLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay errores registrados',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: allLogs.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        final log = allLogs[allLogs.length - 1 - index];
                        final isError = log.contains('Error') ||
                            log.contains('error') ||
                            log.contains('Exception') ||
                            log.contains('FATAL');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: SelectableText(
                            log,
                            style: TextStyle(
                              color: isError ? Colors.redAccent : Colors.white70,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
