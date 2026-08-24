import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/logger.dart';
import '../../firebase_options.dart';
import '../datasources/category_local_data_source.dart';
import '../datasources/product_local_data_source.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

/// Inicializa Firebase y Hive, ejecuta la migración de claves y siembra
/// los datos por defecto. Equivale al arranque original de `main()`.
class AppInitializer {
  AppInitializer({this.logger = const AppLogger()});

  static const String settingsBoxName = 'settingsBox';

  final AppLogger logger;

  late final CategoryLocalDataSource categories;
  late final ProductLocalDataSource products;
  late final Box<dynamic> settings;

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
    await _initFirebase();
    await _initHive();

    categories = CategoryLocalDataSource(
      Hive.box<CategoryModel>(CategoryLocalDataSource.boxName),
    );
    products = ProductLocalDataSource(
      Hive.box<ProductModel>(ProductLocalDataSource.boxName),
    );
    settings = Hive.box(settingsBoxName);

    _normalizeProductKeys();
    await _migrateLegacyCategories();
    await _seedDefaults();
  }

  /// Vacía los datos locales del usuario anterior (categorías y productos).
  /// Se usa al cambiar de cuenta para que cada usuario empiece con lo suyo.
  Future<void> clearUserData() async {
    await Hive.box<CategoryModel>(CategoryLocalDataSource.boxName).clear();
    await Hive.box<ProductModel>(ProductLocalDataSource.boxName).clear();
  }

  /// Siembra categorías y productos por defecto si las cajas están vacías
  /// (primer arranque de un usuario sin datos en la nube).
  Future<void> seedIfEmpty() => _seedDefaults();

  Future<void> _initFirebase() async {    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (err) {
      logger.info('Firebase ya estaba inicializado: $err');
    }
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());

    await Hive.openBox<CategoryModel>(CategoryLocalDataSource.boxName);
    await Hive.openBox<ProductModel>(ProductLocalDataSource.boxName);
    await Hive.openBox<dynamic>(settingsBoxName);
  }

  /// MIGRACIÓN: normaliza la clave de cada producto a su nameKey y fusiona
  /// duplicados físicos heredados (claves numéricas de versiones anteriores).
  void _normalizeProductKeys() {
    final box = Hive.box<ProductModel>(ProductLocalDataSource.boxName);
    final merged = <String, ProductModel>{};
    for (final model in box.values) {
      final cleanKey = model.nameKey.trim();
      merged[cleanKey] = ProductModel(
        nameKey: cleanKey,
        categoryKey: model.categoryKey,
        isToBuy: model.isToBuy,
        emoji: model.emoji,
        imagePath: model.imagePath,
        isBuyScreen: model.isBuyScreen,
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
      final cleanKey = model.nameKey.trim();
      merged[cleanKey] = ProductModel(
        nameKey: cleanKey,
        categoryKey: categoryKey,
        isToBuy: model.isToBuy,
        emoji: model.emoji,
        imagePath: model.imagePath,
        isBuyScreen: model.isBuyScreen,
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
    }

    if (products.isEmpty) {
      const defaultProducts = [
        ('Milk', 'Breakfast', '🥛'),
        ('Bread', 'Breakfast', '🍞'),
        ('Butter', 'Breakfast', '🧈'),
        ('Cheese', 'Breakfast', '🧀'),
        ('Eggs', 'Breakfast', '🥚'),
        ('Coffee', 'Breakfast', '☕'),
        ('Apples', 'Fruits', '🍎'),
        ('Bananas', 'Fruits', '🍌'),
        ('Oranges', 'Fruits', '🍊'),
        ('Tomatoes', 'Vegetables', '🍅'),
        ('Potatoes', 'Vegetables', '🥔'),
        ('Onions', 'Vegetables', '🧅'),
        ('Chicken', 'Meats', '🍗'),
        ('Minced Meat', 'Meats', '🥩'),
        ('Fish', 'Meats', '🐟'),
        ('Rice', 'Kitchen', '🍚'),
        ('Pasta', 'Kitchen', '🍝'),
        ('Olive Oil', 'Kitchen', '🫒'),
        ('Salt', 'Kitchen', '🧂'),
        ('Water', 'Drinks', '💧'),
        ('Juice', 'Drinks', '🧃'),
        ('Wine', 'Drinks', '🍷'),
        ('Detergent', 'Cleaning', '🧼'),
        ('Toilet Paper', 'Cleaning', '🧻'),
        ('Trash Bags', 'Cleaning', '🗑️'),
        ('Toothpaste', 'Personal care', '🦷'),
        ('Shampoo', 'Personal care', '🧴'),
      ];

      for (final (name, category, emoji) in defaultProducts) {
        await products.put(ProductModel(
          nameKey: name,
          categoryKey: category,
          isToBuy: false,
          emoji: emoji,
          isBuyScreen: false,
        ));
      }
    }
  }
}
