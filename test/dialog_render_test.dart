import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buy_and_stock/core/utils/product_asset_catalog.dart';
import 'package:buy_and_stock/presentation/app_settings.dart';
import 'package:buy_and_stock/presentation/localization/app_localizations.dart';
import 'package:buy_and_stock/presentation/widgets/add_product_dialog.dart';

void main() {
  setUpAll(() async {
    await ProductAssetCatalog.instance.ensureLoaded();
    for (final k in const [
      'fruits', 'vegetables', 'meats', 'drinks', 'breakfast',
      'cleaning', 'kitchen', 'personal_care',
    ]) {
      // ignore: avoid_print
      print('pngs[$k]=${ProductAssetCatalog.instance.pngsFor(k).length}');
    }
    // ignore: avoid_print
    print('allPngs.total=${ProductAssetCatalog.instance.allPngs().length}');
  });

  Widget app() => AppSettings(
        notifier: ValueNotifier(AppSettingsData(
          themeMode: ThemeMode.light,
          isGridView: false,
          language: 'es',
        )),
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SizedBox.expand()),
        ),
      );

  testWidgets('categoria personalizada (Receta): un solo item', (tester) async {
    await tester.pumpWidget(app());
    final ctx = tester.element(find.byType(Scaffold));
    ctx.findAncestorStateOfType<NavigatorState>()!.push(
      DialogRoute<void>(
        context: ctx,
        builder: (dialogContext) => const AddProductDialog(
          categories: ['Receta'],
          initialCategory: 'Receta',
          isBuyScreen: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ex = tester.takeException();
    // ignore: avoid_print
    print('EXCEPTION=$ex');
    final dialog = find.byType(AlertDialog);
    final found = dialog.evaluate().isNotEmpty;
    // ignore: avoid_print
    print('AlertDialogFound=$found');
    if (found) {
      final rect = tester.getRect(dialog);
      // ignore: avoid_print
      print('ALERTDIALOGRECT=$rect');
    }
  });

  testWidgets('categoria con pngs propios (fruits): un solo item', (tester) async {
    await tester.pumpWidget(app());
    final ctx = tester.element(find.byType(Scaffold));
    ctx.findAncestorStateOfType<NavigatorState>()!.push(
      DialogRoute<void>(
        context: ctx,
        builder: (dialogContext) => const AddProductDialog(
          categories: ['fruits'],
          initialCategory: 'fruits',
          isBuyScreen: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ex = tester.takeException();
    // ignore: avoid_print
    print('EXCEPTION_FRUITS=$ex');
    final dialog = find.byType(AlertDialog);
    final found = dialog.evaluate().isNotEmpty;
    // ignore: avoid_print
    print('AlertDialogFound_FRUITS=$found');
    if (found) {
      final rect = tester.getRect(dialog);
      // ignore: avoid_print
      print('ALERTDIALOGRECT_FRUITS=$rect');
    }
  });
}