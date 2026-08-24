import 'package:flutter/material.dart';

class AppSettings extends InheritedNotifier<ValueNotifier<AppSettingsData>> {
  const AppSettings({
    super.key,
    required ValueNotifier<AppSettingsData> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppSettingsData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettings>()!
        .notifier!
        .value;
  }

  static ValueNotifier<AppSettingsData> notifierOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettings>()!
        .notifier!;
  }
}

class AppSettingsData {
  final ThemeMode themeMode;
  final bool isGridView;
  final String language;

  AppSettingsData({
    required this.themeMode,
    required this.isGridView,
    required this.language,
  });

  AppSettingsData copyWith({
    ThemeMode? themeMode,
    bool? isGridView,
    String? language,
  }) {
    return AppSettingsData(
      themeMode: themeMode ?? this.themeMode,
      isGridView: isGridView ?? this.isGridView,
      language: language ?? this.language,
    );
  }
}
