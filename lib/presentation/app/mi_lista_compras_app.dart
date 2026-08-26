import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/di.dart';
import '../../data/bootstrap/app_initializer.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../app_settings.dart';
import '../localization/app_localizations.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigator_screen.dart';

class MiListaComprasApp extends StatefulWidget {
  const MiListaComprasApp({super.key});

  @override
  State<MiListaComprasApp> createState() => _MiListaComprasAppState();
}

class _MiListaComprasAppState extends State<MiListaComprasApp> {
  late final ValueNotifier<AppSettingsData> _settingsNotifier;

  final AuthRepository _authRepository = sl<AuthRepository>();
  late final Stream<AuthUser?> _authStateStream;

  @override
  void initState() {
    super.initState();
    _settingsNotifier = ValueNotifier(_loadSettings());
    _settingsNotifier.addListener(_persistSettings);
    _authStateStream = _authRepository.authStateChanges();
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

  static const Color _seedColor = Color(0xFF059669);

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
            home: StreamBuilder(
              stream: _authStateStream,
              builder: (context, snapshot) {
                final authUser =
                    snapshot.data ?? _authRepository.currentUser;

                if (authUser != null) {
                  return const MainNavigatorScreen();
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
