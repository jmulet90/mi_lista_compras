import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/di.dart';
import '../../core/session_status.dart';
import '../../data/bootstrap/app_initializer.dart';
import '../app_settings.dart';
import '../localization/app_localizations.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigator_screen.dart';
import '../screens/shopping_suggestion_screen.dart';
import '../screens/splash_screen.dart';
import '../services/local_notification_service.dart';

class MiListaComprasApp extends StatefulWidget {
  const MiListaComprasApp({super.key});

  @override
  State<MiListaComprasApp> createState() => _MiListaComprasAppState();
}

class _MiListaComprasAppState extends State<MiListaComprasApp> {
  late final ValueNotifier<AppSettingsData> _settingsNotifier;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _settingsNotifier = ValueNotifier(_loadSettings());
    _settingsNotifier.addListener(_persistSettings);
    _watchNotificationTaps();
  }

  @override
  void dispose() {
    _settingsNotifier.removeListener(_persistSettings);
    _settingsNotifier.dispose();
    super.dispose();
  }

  /// Escucha los toques en notificaciones (con la app abierta o recién
  /// abierta desde una notificación) y navega al detalle de la sugerencia.
  void _watchNotificationTaps() {
    try {
      final service = sl<LocalNotificationService>();
      service.tappedPayload.addListener(() {
        final payload = service.tappedPayload.value;
        if (payload != null) _openSuggestion(payload);
      });
      // Cubre el caso de arranque en frío: el valor ya pudo haberse fijado
      // durante bootstrap(), antes de que este listener existiera.
      if (service.tappedPayload.value != null) {
        _openSuggestion(service.tappedPayload.value!);
      }
    } catch (_) {
      // El servicio de notificaciones es una mejora opcional.
    }
  }

  /// Espera (con reintentos breves) a que la sesión esté lista antes de
  /// navegar, para no empujar una ruta encima del splash o del login.
  Future<void> _openSuggestion(String notificationId, [int attempt = 0]) async {
    final navigator = _navigatorKey.currentState;
    final ready = sl<SessionStatusNotifier>().value == AppSessionPhase.ready;
    if (navigator == null || !ready) {
      if (attempt >= 15) return; // ~4.5s de margen, luego se descarta.
      await Future.delayed(const Duration(milliseconds: 300));
      return _openSuggestion(notificationId, attempt + 1);
    }
    try {
      sl<LocalNotificationService>().tappedPayload.value = null;
    } catch (_) {}
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ShoppingSuggestionScreen(notificationId: notificationId),
      ),
    );
  }

  AppSettingsData _loadSettings() {
    try {
      final box = sl<AppInitializer>().settings;
      final storedLang = box.get('language') as String? ?? 'es';
      return AppSettingsData(
        themeMode: ThemeMode.values.firstWhere(
          (mode) => mode.name == box.get('themeMode'),
          orElse: () => ThemeMode.light,
        ),
        isGridView: box.get('isGridView') as bool? ?? false,
        language: AppLocalizations.isSupported(storedLang) ? storedLang : 'es',
      );
    } catch (_) {
      return AppSettingsData(
        themeMode: ThemeMode.light,
        isGridView: false,
        language: 'es',
      );
    }
  }

  void _persistSettings() {
    try {
      final box = sl<AppInitializer>().settings;
      final settings = _settingsNotifier.value;
      box.put('themeMode', settings.themeMode.name);
      box.put('isGridView', settings.isGridView);
      box.put('language', settings.language);
    } catch (_) {}
  }

  static const Color _seedColor = Color(0xFFC27A22);

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSettings(
      notifier: _settingsNotifier,
      child: ValueListenableBuilder<AppSettingsData>(
        valueListenable: _settingsNotifier,
        builder: (context, settings, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Buy&Stock',
            onGenerateTitle: (context) =>
                AppLocalizations.of(context).appName,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(settings.language),
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: settings.themeMode,
            home: ValueListenableBuilder<AppSessionPhase>(
              valueListenable: sl<SessionStatusNotifier>(),
              builder: (context, phase, child) {
                switch (phase) {
                  case AppSessionPhase.loading:
                  case AppSessionPhase.authenticatedLoadingData:
                    return const SplashScreen();
                  case AppSessionPhase.ready:
                    return const MainNavigatorScreen();
                  case AppSessionPhase.unauthenticated:
                    return const LoginScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}