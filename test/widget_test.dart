import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buy_and_stock/presentation/app_settings.dart';

void main() {
  test('AppSettingsData copyWith conserva valores no modificados', () {
    final settings = AppSettingsData(
      themeMode: ThemeMode.light,
      isGridView: false,
      language: 'es',
    );

    final updated = settings.copyWith(themeMode: ThemeMode.dark);

    expect(updated.themeMode, ThemeMode.dark);
    expect(updated.isGridView, false);
    expect(updated.language, 'es');
  });
}
