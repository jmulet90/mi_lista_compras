import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../presentation/localization/app_localizations.dart';
import '../../core/crash_overlay.dart';
import '../../core/logger.dart';
import '../../core/utils/product_asset_catalog.dart';
import '../../firebase_options.dart';
import '../datasources/category_local_data_source.dart';
import '../datasources/notification_center_local_data_source.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/purchase_history_local_data_source.dart';
import '../models/app_notification_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/purchase_event_model.dart';

/// Inicializa Firebase y Hive, ejecuta la migración de claves y siembra
/// los datos por defecto. Equivale al arranque original de `main()`.
class AppInitializer {
  AppInitializer({this.logger = const AppLogger()});

  static const String settingsBoxName = 'settingsBox';
  static const String deletedProductsBoxName = 'deletedProductKeys';
  static const String deletedCategoriesBoxName = 'deletedCategoryKeys';
  static const String subcategoriesBoxName = 'subcategoriesBox';

  final AppLogger logger;

  late final CategoryLocalDataSource categories;
  late final ProductLocalDataSource products;
  late final Box<dynamic> settings;
  late final Box<String> deletedProductKeys;
  late final Box<String> deletedCategoryKeys;
  late final Box<String> subcategories;
  late final PurchaseHistoryLocalDataSource purchaseHistory;
  late final NotificationCenterLocalDataSource notificationCenter;

  /// Claves canónicas actuales de la app (deben coincidir con las semillas).
  static const List<String> _canonicalCategories = [
    'Kitchen',
    'Personal care',
    'Cleaning',
    'Meats',
    'Drinks',
    'Breakfast',
    'Fruits',
    'Vegetables',
    'Baby',
  ];

  static const Map<String, String> _seedCategoryEmoji = {
    'Kitchen': '🍲',
    'Personal care': '🧖',
    'Cleaning': '✨',
    'Meats': '🥩',
    'Drinks': '🥂',
    'Breakfast': '🥐',
    'Fruits': '🍎',
    'Vegetables': '🥦',
    'Baby': '🍼',
  };

  /// Nombres legados que apuntan a UNA categoría canónica (versiones
  /// antiguas, mayúsculas distintas o nombres en español).
  static const Map<String, String> _singleCategoryAliases = {
    'kitchen': 'Kitchen',
    'cocina': 'Kitchen',
    'personal care': 'Personal care',
    'cuidado personal': 'Personal care',
    'cleaning': 'Cleaning',
    'limpieza': 'Cleaning',
    'meats': 'Meats',
    'meat': 'Meats',
    'carnes': 'Meats',
    'carne': 'Meats',
    'drinks': 'Drinks',
    'bebidas': 'Drinks',
    'breakfast': 'Breakfast',
    'desayuno': 'Breakfast',
    'fruits': 'Fruits',
    'fruit': 'Fruits',
    'frutas': 'Fruits',
    'vegetables': 'Vegetables',
    'vegetable': 'Vegetables',
    'verduras': 'Vegetables',
    'verdura': 'Vegetables',
    'vegetales': 'Vegetables',
    'baby': 'Baby',
    'bebe': 'Baby',
  };

  /// Nombres legados combinados que deben repartirse entre varias canónicas.
  static const Map<String, List<String>> _splitCategoryAliases = {
    'fruits & veg': ['Fruits', 'Vegetables'],
    'fruits and veg': ['Fruits', 'Vegetables'],
    'fruits & vegetables': ['Fruits', 'Vegetables'],
    'fruits and vegetables': ['Fruits', 'Vegetables'],
    'frutas y verduras': ['Fruits', 'Vegetables'],
    'frutas y vegetales': ['Fruits', 'Vegetables'],
  };

  static const Set<String> _fruitHints = {
    'apple', 'apples', 'banana', 'bananas', 'platano', 'platanos', 'naranja',
    'naranjas', 'orange', 'oranges', 'limon', 'limones', 'lemon', 'lemons',
    'uvas', 'grape', 'grapes', 'sandia', 'watermelon', 'fresa', 'fresas',
    'strawberry', 'strawberries', 'aguacate', 'avocado', 'avocados', 'pera',
    'peras', 'pear', 'pears', 'mango', 'durazno', 'melocoton', 'peach',
    'kiwi', 'pina', 'pinas', 'pineapple',
  };

  static const Set<String> _veggieHints = {
    'tomate', 'tomates', 'tomato', 'tomatoes', 'patata', 'patatas', 'papa',
    'papas', 'potato', 'potatoes', 'cebolla', 'cebollas', 'onion', 'onions',
    'zanahoria', 'zanahorias', 'carrot', 'carrots', 'lechuga', 'lettuce',
    'brocoli', 'broccoli', 'pepino', 'pepinos', 'cucumber', 'ajo', 'ajos',
    'garlic', 'espinaca', 'espinacas', 'spinach', 'pimiento', 'pepper',
  };

  Future<void> initialize() async {
    CrashOverlay.log('AppInitializer.initialize() started');
    await _initFirebase();
    CrashOverlay.log('Firebase initialized, starting Hive...');
    await _initHive();
    CrashOverlay.log('Hive initialized');

    categories = CategoryLocalDataSource(
      Hive.box<CategoryModel>(CategoryLocalDataSource.boxName),
    );
    products = ProductLocalDataSource(
      Hive.box<ProductModel>(ProductLocalDataSource.boxName),
    );
    settings = Hive.box(settingsBoxName);
    deletedProductKeys = Hive.box(deletedProductsBoxName);
    deletedCategoryKeys = Hive.box(deletedCategoriesBoxName);
    subcategories = Hive.box(subcategoriesBoxName);
    purchaseHistory = PurchaseHistoryLocalDataSource(
      Hive.box<PurchaseEventModel>(PurchaseHistoryLocalDataSource.boxName),
    );
    notificationCenter = NotificationCenterLocalDataSource(
      Hive.box<AppNotificationModel>(NotificationCenterLocalDataSource.boxName),
    );

    CrashOverlay.log('Running product key normalization...');
    _normalizeProductKeys();
    CrashOverlay.log('Running legacy category migration...');
    await _migrateLegacyCategories();
    CrashOverlay.log('Seeding defaults...');
    await _seedDefaults();
    CrashOverlay.log(
        'After seed: ${products.getAll().length} products, ${categories.getAll().length} categories');
    CrashOverlay.log('AppInitializer.initialize() completed');
  }

  /// Vacía los datos locales del usuario anterior (categorías y productos).
  /// Se usa al cambiar de cuenta para que cada usuario empiece con lo suyo.
  Future<void> clearUserData() async {
    await Hive.box<CategoryModel>(CategoryLocalDataSource.boxName).clear();
    await Hive.box<ProductModel>(ProductLocalDataSource.boxName).clear();
    await Hive.box<String>(subcategoriesBoxName).clear();
    // El historial de compras y las notificaciones son comportamiento por
    // usuario: no tendría sentido mezclarlos entre cuentas distintas.
    await Hive.box<PurchaseEventModel>(PurchaseHistoryLocalDataSource.boxName).clear();
    await Hive.box<AppNotificationModel>(NotificationCenterLocalDataSource.boxName).clear();
  }

  static const String lastAuthUidKey = 'last_auth_uid';

  /// UID de la última sesión iniciada sin haber cerrado sesión. Se usa para
  /// no mostrar el login en el arranque en frío mientras Firebase restaura
  /// la sesión de forma asíncrona (que demora algunos segundos).
  String? get lastAuthUid => settings.get(lastAuthUidKey) as String?;

  Future<void> setLastAuthUid(String? uid) async {
    if (uid == null) {
      await settings.delete(lastAuthUidKey);
    } else {
      await settings.put(lastAuthUidKey, uid);
    }
  }

  /// Siembra categorías y productos por defecto si las cajas están vacías
  /// (primer arranque de un usuario sin datos en la nube).
  Future<void> seedIfEmpty() => _seedDefaults();

  Future<void> _initFirebase() async {
    try {
      CrashOverlay.log('Firebase.initializeApp() calling...');
      CrashOverlay.log('Firebase apps count: ${Firebase.apps.length}');
      if (Firebase.apps.isEmpty) {
        final options = DefaultFirebaseOptions.currentPlatform;
        CrashOverlay.log('Firebase options appId: ${options.appId}');
        CrashOverlay.log('Firebase options apiKey: ${options.apiKey.substring(0, 10)}...');
        await Firebase.initializeApp(
          options: options,
        );
        CrashOverlay.log('Firebase.initializeApp() SUCCESS');
      } else {
        CrashOverlay.log('Firebase already initialized, skipping');
      }
    } catch (err, st) {
      CrashOverlay.logError('Firebase init failed', err, st);
      logger.info('Firebase ya estaba inicializado: $err');
    }
  }

  Future<void> _initHive() async {
    CrashOverlay.log('Hive.initFlutter() calling...');
    await Hive.initFlutter();
    CrashOverlay.log('Registering Hive adapters...');
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(PurchaseEventModelAdapter());
    Hive.registerAdapter(AppNotificationModelAdapter());

    CrashOverlay.log('Opening Hive boxes...');
    await Hive.openBox<CategoryModel>(CategoryLocalDataSource.boxName);
    await Hive.openBox<ProductModel>(ProductLocalDataSource.boxName);
    await Hive.openBox<dynamic>(settingsBoxName);
    await Hive.openBox<String>(deletedProductsBoxName);
    await Hive.openBox<String>(deletedCategoriesBoxName);
    await Hive.openBox<String>(subcategoriesBoxName);
    await Hive.openBox<PurchaseEventModel>(PurchaseHistoryLocalDataSource.boxName);
    await Hive.openBox<AppNotificationModel>(NotificationCenterLocalDataSource.boxName);
    CrashOverlay.log('All Hive boxes opened successfully');
  }

  /// MIGRACIÓN: normaliza la clave de cada producto a su nameKey y fusiona
  /// duplicados físicos heredados (claves numéricas de versiones anteriores).
    void _normalizeProductKeys() {
    final box = Hive.box<ProductModel>(ProductLocalDataSource.boxName);
    final merged = <String, ProductModel>{};
    for (final model in box.values) {
      final cleanKey = model.nameKey.trim().toLowerCase();
      merged[cleanKey] = ProductModel(
        nameKey: model.nameKey.trim(),
        categoryKey: model.categoryKey,
        isToBuy: model.isToBuy,
        emoji: model.emoji,
        imagePath: model.imagePath,
        isBuyScreen: model.isBuyScreen,
        imageId: model.imageId,
        quantity: model.quantity,
        unit: model.unit,
        subcategory: model.subcategory,
      );
    }
    box.clear();
    box.putAll(merged);
  }

  /// MIGRACIÓN: normaliza categorías legadas de versiones anteriores
  /// (p. ej. "Fruits & Veg" combinada) a las claves canónicas actuales,
  /// reasignando sus productos. Corre antes de sembrar defaults.
  Future<void> _migrateLegacyCategories() async {
    final legacy = categories
        .getAll()
        .where((c) => !_isCanonicalKey(c.key))
        .toList();
    if (legacy.isEmpty) return;

    logger.info(
        'Migrando ${legacy.length} categoría(s) legada(s): '
        '${legacy.map((c) => c.key).join(', ')}');

    for (final cat in legacy) {
      final n = cat.key.trim().toLowerCase();
      final splitTargets = _splitCategoryAliases[n];
      final singleTarget = _singleCategoryAliases[n];

      if (splitTargets != null) {
        for (final target in splitTargets) {
          await _ensureCanonical(target);
        }
        await _reassignProducts(legacyKey: cat.key, pickTarget: (model) {
          final words = model.nameKey
              .trim()
              .toLowerCase()
              .split(RegExp(r'[^a-zñ]+'))
            ..removeWhere((w) => w.isEmpty);
          for (final w in words) {
            if (_fruitHints.contains(w)) return 'Fruits';
            if (_veggieHints.contains(w)) return 'Vegetables';
          }
          return splitTargets.first;
        });
        await categories.delete(cat.key);
      } else if (singleTarget != null) {
        final targetExists = categories.getAll().any(
              (c) => c.key.trim().toLowerCase() == singleTarget.toLowerCase(),
            );
        if (targetExists) {
          await _reassignProducts(
            legacyKey: cat.key,
            pickTarget: (_) => singleTarget,
          );
          await categories.delete(cat.key);
        } else {
          // Renombrar conservando emoji/imagen de la legada.
          await categories.update(
            currentKey: cat.key,
            model: CategoryModel(
              key: singleTarget,
              emoji: cat.emoji ?? _seedCategoryEmoji[singleTarget],
              imagePath: cat.imagePath,
            ),
          );
        }
      }
      // Claves desconocidas se conservan tal cual (datos del usuario).
    }
  }

  bool _isCanonicalKey(String key) =>
      _canonicalCategories.any((c) => c.toLowerCase() == key.trim().toLowerCase());

  Future<void> _ensureCanonical(String key) async {
    if (!categories.exists(key)) {
      await categories.add(CategoryModel(
        key: key,
        emoji: _seedCategoryEmoji[key] ?? '📦',
      ));
    }
  }

  /// Reasigna los productos de [legacyKey] reconstruyendo la caja completa
  /// (mismo enfoque que _normalizeProductKeys: dedupe por nameKey).
  Future<void> _reassignProducts({
    required String legacyKey,
    required String Function(ProductModel model) pickTarget,
  }) async {
    final box = Hive.box<ProductModel>(ProductLocalDataSource.boxName);
    final legacyNorm = legacyKey.trim().toLowerCase();
    final merged = <String, ProductModel>{};
    for (final model in box.values) {
      var categoryKey = model.categoryKey;
      if (categoryKey.trim().toLowerCase() == legacyNorm) {
        categoryKey = pickTarget(model);
      }
      final cleanKey = model.nameKey.trim().toLowerCase();
      merged[cleanKey] = ProductModel(
        nameKey: model.nameKey.trim(),
        categoryKey: categoryKey,
        isToBuy: model.isToBuy,
        emoji: model.emoji,
        imagePath: model.imagePath,
        isBuyScreen: model.isBuyScreen,
        imageId: model.imageId,
        quantity: model.quantity,
        unit: model.unit,
        subcategory: model.subcategory,
      );
    }
    await box.clear();
    await box.putAll(merged);
  }

  Future<void> _seedDefaults() async {
    if (categories.isEmpty) {
      await categories.addAll([
        for (final key in _canonicalCategories)
          CategoryModel(key: key, emoji: _seedCategoryEmoji[key]),
      ]);
    } else {
      // Usuario existente: añadir solo las categorías canónicas que falten
      // (p. ej. "Baby" añadida en una versión nueva) sin tocar las suyas.
      for (final key in _canonicalCategories) {
        if (!categories.exists(key)) {
          await categories.add(CategoryModel(
            key: key,
            emoji: _seedCategoryEmoji[key],
          ));
        }
      }
    }

    // Catálogo de productos semilla derivado dinámicamente de los PNG en
    // assets. Es ADITIVO e IDEMPOTENTE: cada arranque se asegura de que
    // exista un producto por cada PNG (así los PNG nuevos aparecen solos),
    // pero NUNCA borra los productos que el usuario creó manualmente.
    await _seedProductsFromAssets();
  }

  /// Asegura que exista un producto semilla por cada PNG del catálogo.
  ///
  /// El [nameKey] se deriva del nombre del archivo en formato Título, p. ej.
  /// `white grapes.png` -> `White Grapes`. Los productos ya presentes (por su
  /// clave lowercased) no se tocan; si el usuario editó uno, se conserva su
  /// estado, pero la imagen vuelve a apuntar al PNG de assets.
  Future<void> _seedProductsFromAssets() async {
    final catalog = ProductAssetCatalog.instance;
    await catalog.ensureLoaded();
    final existingProducts = products.getAll();
    final existingNames = {
      for (final p in existingProducts) p.nameKey.trim().toLowerCase(),
    };

    // Si el catálogo de PNG no se pudo cargar (p. ej. manifiesto de assets no
    // disponible), se siembra un respaldo mínimo con las rutas reales de los
    // assets para que la app nunca quede solo con categorías y sin productos.
    final Map<String, List<String>> entries = catalog.pngCount == 0
        ? _fallbackSeedPngs
        : {
            for (final category in _canonicalCategories)
              category: catalog.pngsFor(category),
          };

    for (final entry in entries.entries) {
      final category = entry.key;
      for (final assetPath in entry.value) {
        final fileName = assetPath.split('/').last;
        final nameKey = _canonicalSeedName(fileName);
        final cleanKey = nameKey.toLowerCase();
        if (existingNames.contains(cleanKey)) continue;
        await products.put(
          ProductModel(
            nameKey: nameKey,
            categoryKey: category,
            isToBuy: false,
            emoji: assetPath,
            isBuyScreen: false,
          ),
          key: cleanKey,
        );
      }
    }
  }

  /// Productos mínimos de respaldo usados cuando el catálogo de PNG no se
  /// pudo cargar. Son rutas reales que existen en `assets/images/emojis/products/`.
  static const Map<String, List<String>> _fallbackSeedPngs = {
    'Breakfast': [
      'assets/images/emojis/products/breakfast/bread.png',
      'assets/images/emojis/products/breakfast/ball bread.png',
      'assets/images/emojis/products/breakfast/coffee.png',
      'assets/images/emojis/products/breakfast/croassaint.png',
      'assets/images/emojis/products/breakfast/milk.png',
      'assets/images/emojis/products/breakfast/mini baguette.png',
    ],
    'Fruits': [
      'assets/images/emojis/products/fruits/apples.png',
      'assets/images/emojis/products/fruits/orange.png',
      'assets/images/emojis/products/fruits/white grapes.png',
    ],
    'Kitchen': [
      'assets/images/emojis/products/kitchen/black beans.png',
      'assets/images/emojis/products/kitchen/chickpea.png',
    ],
    'Meats': [
      'assets/images/emojis/products/meats/chicken.png',
      'assets/images/emojis/products/meats/cow.png',
      'assets/images/emojis/products/meats/fish.png',
      'assets/images/emojis/products/meats/pork.png',
      'assets/images/emojis/products/meats/Salmon.png',
    ],
    'Vegetables': [
      'assets/images/emojis/products/vegetables/avocado.png',
      'assets/images/emojis/products/vegetables/beet.png',
      'assets/images/emojis/products/vegetables/carrot.png',
      'assets/images/emojis/products/vegetables/cucumber.png',
      'assets/images/emojis/products/vegetables/lettuce.png',
      'assets/images/emojis/products/vegetables/tomatoes.png',
    ],
  };

  /// `white grapes.png` -> `White Grapes` (título crudo).
  String _titleCaseFromFile(String fileName) {
    final base = fileName.replaceAll(RegExp(r'\.png$'), '');
    final parts = base.split(RegExp(r'[\s_]+'));
    return parts.map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  /// Corrige nombres de archivo históricamente mal escritos que tienen
  /// equivalencia canónica en el diccionario de nombres.
  static const Map<String, String> _seedNameAliases = {
    'Croassaint': 'Croissant',
    // 'girassol oil.png' es un fallo ortográfico del archivo; el diccionario usa
    // la clave canónica en inglés.
    'Girassol Oil': 'Sunflower oil',
  };

  /// Deriva el [nameKey] canónico de un producto semilla a partir del nombre
  /// del archivo PNG. Si el nombre (normalizado) existe en el diccionario de
  /// nombres (AppLocalizations._names), se usa esa clave canónica exacta para
  /// que el display y las ediciones nunca generen un rename por mayúsculas.
  /// Si no existe, se devuelve el título crudo del archivo.
  String _canonicalSeedName(String fileName) {
    final raw = _titleCaseFromFile(fileName);
    final alias = _seedNameAliases[raw];
    final resolved = AppLocalizations.findNameKey(alias ?? raw);
    return resolved ?? (alias ?? raw);
  }
}
