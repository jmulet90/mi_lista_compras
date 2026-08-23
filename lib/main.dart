import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

// Imports de Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mi_lista_compras/screens/login_screen.dart';
import '/services/auth_service.dart';

// NUEVOS IMPORTS: Para la pantalla de permisos y el gestor de emojis
import 'package:mi_lista_compras/screens/manage_collaborators_screen.dart';

part 'main.g.dart';

// ==========================================
// SERVICIO DE SINCRONIZACIÓN HIVE <-> FIRESTORE NEW
// ==========================================
class SyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> getOwnerEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return null;

    // Verificamos si es colaborador
    try {
      final snapshot = await _db
          .collection('collaborators')
          .where('collaboratorEmail', isEqualTo: user.email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('ownerEmail') as String?;
      }
    } catch (e) {
      print("Error obteniendo owner para sincronización: $e");
    }
    return user.email; // Es el dueño
  }

  void startSync() async {
    final ownerEmail = await getOwnerEmail();
    if (ownerEmail == null) return;

    final productBox = Hive.box<Product>('productsBox');

    // Escuchar cambios en la nube y actualizar local usando nameKey como clave
    _db.collection('users_data').doc(ownerEmail).collection('products')
        .snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          if (data != null) {
            final product = Product(
              nameKey: data['nameKey'] ?? '',
              categoryKey: data['categoryKey'] ?? '',
              isToBuy: data['isToBuy'] ?? false,
              emoji: data['emoji'],
              isBuyScreen: data['isBuyScreen'] ?? false,
            );
            // Usamos el nameKey como clave única en Hive
            productBox.put(product.nameKey.trim(), product);
          }
        } else if (change.type == DocumentChangeType.removed) {
          productBox.delete(change.doc.id);
        }
      }
    });
  }

  // Mantenemos los 2 parámetros para que no fallen tus otras pantallas,
  // pero forzamos a que el ID en Firestore sea siempre el nameKey limpio.
  Future<void> syncProductUp(String productId, Product product) async {
    final ownerEmail = await getOwnerEmail();
    if (ownerEmail == null) return;

    final docId = product.nameKey.trim();

    try {
      await _db
          .collection('users_data')
          .doc(ownerEmail)
          .collection('products')
          .doc(docId)
          .set({
        'nameKey': product.nameKey,
        'categoryKey': product.categoryKey,
        'isToBuy': product.isToBuy,
        'emoji': product.emoji,
        'isBuyScreen': product.isBuyScreen,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error al subir producto a la nube: $e");
    }
  }

  Future<void> syncProductDelete(String productId) async {
    final ownerEmail = await getOwnerEmail();
    if (ownerEmail == null) return;

    try {
      await _db
          .collection('users_data')
          .doc(ownerEmail)
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      print("Error al eliminar producto de la nube: $e");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intentamos inicializar Firebase protegiéndolo de duplicados
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print("Firebase ya estaba inicializado: $e");
  }

  // 2. Inicialización de Hive
  await Hive.initFlutter();

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(CategoryItemAdapter());

  var categoryBox = await Hive.openBox<CategoryItem>('categoriesBox');
  var productBox = await Hive.openBox<Product>('productsBox');

  // Inicializar Sincronización si hay un usuario autenticado
  if (FirebaseAuth.instance.currentUser != null) {
    SyncService().startSync();
  }

  // 3. Rellenar categorías por defecto si está vacío
  if (categoryBox.isEmpty) {
    categoryBox.addAll([
      CategoryItem(key: 'Kitchen', emoji: '🍲'),
      CategoryItem(key: 'Personal care', emoji: '🧖'),
      CategoryItem(key: 'Cleaning', emoji: '✨'),
      CategoryItem(key: 'Meats', emoji: '🥩'),
      CategoryItem(key: 'Drinks', emoji: '🥂'),
      CategoryItem(key: 'Breakfast', emoji: '🥐'),
      CategoryItem(key: 'Fruits', emoji: '🍎'),
      CategoryItem(key: 'Vegetables', emoji: '🥦')
    ]);
  }

  // 4. Rellenar productos por defecto usando nameKey como clave única en Hive
  if (productBox.isEmpty) {
    final defaultProducts = [
      Product(nameKey: 'Milk', categoryKey: 'Breakfast', isToBuy: false, emoji: '🥛', isBuyScreen: false),
      Product(nameKey: 'Bread', categoryKey: 'Breakfast', isToBuy: false, emoji: '🍞', isBuyScreen: false),
      Product(nameKey: 'Butter', categoryKey: 'Breakfast', isToBuy: false, emoji: '🧈', isBuyScreen: false),
      Product(nameKey: 'Cheese', categoryKey: 'Breakfast', isToBuy: false, emoji: '🧀', isBuyScreen: false),
      Product(nameKey: 'Eggs', categoryKey: 'Breakfast', isToBuy: false, emoji: '🥚', isBuyScreen: false),
      Product(nameKey: 'Coffee', categoryKey: 'Breakfast', isToBuy: false, emoji: '☕', isBuyScreen: false),

      Product(nameKey: 'Apples', categoryKey: 'Fruits', isToBuy: false, emoji: '🍎', isBuyScreen: false),
      Product(nameKey: 'Bananas', categoryKey: 'Fruits', isToBuy: false, emoji: '🍌', isBuyScreen: false),
      Product(nameKey: 'Oranges', categoryKey: 'Fruits', isToBuy: false, emoji: '🍊', isBuyScreen: false),

      Product(nameKey: 'Tomatoes', categoryKey: 'Vegetables', isToBuy: false, emoji: '🍅', isBuyScreen: false),
      Product(nameKey: 'Potatoes', categoryKey: 'Vegetables', isToBuy: false, emoji: '🥔', isBuyScreen: false),
      Product(nameKey: 'Onions', categoryKey: 'Vegetables', isToBuy: false, emoji: '🧅', isBuyScreen: false),

      Product(nameKey: 'Chicken', categoryKey: 'Meats', isToBuy: false, emoji: '🍗', isBuyScreen: false),
      Product(nameKey: 'Minced Meat', categoryKey: 'Meats', isToBuy: false, emoji: '🥩', isBuyScreen: false),
      Product(nameKey: 'Fish', categoryKey: 'Meats', isToBuy: false, emoji: '🐟', isBuyScreen: false),

      Product(nameKey: 'Rice', categoryKey: 'Kitchen', isToBuy: false, emoji: '🍚', isBuyScreen: false),
      Product(nameKey: 'Pasta', categoryKey: 'Kitchen', isToBuy: false, emoji: '🍝', isBuyScreen: false),
      Product(nameKey: 'Olive Oil', categoryKey: 'Kitchen', isToBuy: false, emoji: '🫒', isBuyScreen: false),
      Product(nameKey: 'Salt', categoryKey: 'Kitchen', isToBuy: false, emoji: '🧂', isBuyScreen: false),

      Product(nameKey: 'Water', categoryKey: 'Drinks', isToBuy: false, emoji: '💧', isBuyScreen: false),
      Product(nameKey: 'Juice', categoryKey: 'Drinks', isToBuy: false, emoji: '🧃', isBuyScreen: false),
      Product(nameKey: 'Wine', categoryKey: 'Drinks', isToBuy: false, emoji: '🍷', isBuyScreen: false),

      Product(nameKey: 'Detergent', categoryKey: 'Cleaning', isToBuy: false, emoji: '🧼', isBuyScreen: false),
      Product(nameKey: 'Toilet Paper', categoryKey: 'Cleaning', isToBuy: false, emoji: '🧻', isBuyScreen: false),
      Product(nameKey: 'Trash Bags', categoryKey: 'Cleaning', isToBuy: false, emoji: '🗑️', isBuyScreen: false),

      Product(nameKey: 'Toothpaste', categoryKey: 'Personal care', isToBuy: false, emoji: '🦷', isBuyScreen: false),
      Product(nameKey: 'Shampoo', categoryKey: 'Personal care', isToBuy: false, emoji: '🧴', isBuyScreen: false),
    ];

    for (var product in defaultProducts) {
      productBox.put(product.nameKey.trim(), product);
    }
  }

  // 5. Arrancar la aplicación
  runApp(const MiListaComprasApp());
}

class AppSettings extends InheritedNotifier<ValueNotifier<AppSettingsData>> {
  AppSettings({super.key, required ValueNotifier<AppSettingsData> notifier, required super.child})
      : super(notifier: notifier);

  static AppSettingsData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppSettings>()!.notifier!.value;
  }

  static ValueNotifier<AppSettingsData> notifierOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppSettings>()!.notifier!;
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

class AppLocalizations {
  final String langCode;

  AppLocalizations(this.langCode);

  static AppLocalizations of(BuildContext context) {
    final settings = AppSettings.of(context);
    return AppLocalizations(settings.language);
  }

  String getCategoryName(String key) {
    const Map<String, Map<String, String>> categoriesMap = {
      'Kitchen': {'es': 'Cocina', 'en': 'Kitchen', 'pt': 'Cozinha'},
      'Personal care': {'es': 'Cuidado personal', 'en': 'Personal care', 'pt': 'Cuidados pessoais'},
      'Cleaning': {'es': 'Limpieza', 'en': 'Cleaning', 'pt': 'Limpeza'},
      'Meats': {'es': 'Carnes', 'en': 'Meats', 'pt': 'Carnes'},
      'Drinks': {'es': 'Bebidas', 'en': 'Drinks', 'pt': 'Bebidas'},
      'Breakfast': {'es': 'Desayuno', 'en': 'Breakfast', 'pt': 'Pequeno-almoço'},
      'Fruits': {'es': 'Frutas', 'en': 'Fruits', 'pt': 'Frutas'},
      'Vegetables': {'es': 'Verduras', 'en': 'Vegetables', 'pt': 'Legumes'},
    };
    return categoriesMap[key]?[langCode] ?? key;
  }

  String get buyTitle => 'Comprar - Lista de Compras';
  String get stockTitle => langCode == 'en' ? 'Stock - Inventory' : langCode == 'pt' ? 'Despensa - Inventário' : 'Despensa - Inventario';
  String get navBuy => langCode == 'en' ? 'Buy' : langCode == 'pt' ? 'Comprar' : 'Comprar';
  String get navStock => langCode == 'en' ? 'Stock' : langCode == 'pt' ? 'Despensa' : 'Despensa';
  String get settings => langCode == 'en' ? 'Settings' : langCode == 'pt' ? 'Configurações' : 'Configuraciones';
  String get darkMode => langCode == 'en' ? 'Dark Mode' : langCode == 'pt' ? 'Modo Escuro' : 'Modo Oscuro';
  String get categoryView => langCode == 'en' ? 'Category View' : langCode == 'pt' ? 'Vista de Categorias' : 'Vista de categorías';
  String get list => langCode == 'en' ? 'List' : langCode == 'pt' ? 'Lista' : 'Lista';
  String get gallery => langCode == 'en' ? 'Gallery' : langCode == 'pt' ? 'Galeria' : 'Galería';
  String get language => langCode == 'en' ? 'Language' : langCode == 'pt' ? 'Idioma' : 'Idioma';
  String get addCategory => langCode == 'en' ? 'New Category' : langCode == 'pt' ? 'Nova Categoria' : 'Nueva Categoría';
  String get editCategory => langCode == 'en' ? 'Edit Category' : langCode == 'pt' ? 'Editar Categoria' : 'Editar Categoría';
  String get deleteCategory => langCode == 'en' ? 'Delete Category' : langCode == 'pt' ? 'Eliminar Categoria' : 'Eliminar Categoría';
  String get cancel => langCode == 'en' ? 'Cancel' : langCode == 'pt' ? 'Cancelar' : 'Cancelar';
  String get save => langCode == 'en' ? 'Save' : langCode == 'pt' ? 'Guardar' : 'Guardar';
  String get add => langCode == 'en' ? 'Add' : langCode == 'pt' ? 'Adicionar' : 'Añadir';
  String get delete => langCode == 'en' ? 'Delete' : langCode == 'pt' ? 'Eliminar' : 'Eliminar';
  String get edit => langCode == 'en' ? 'Editar' : langCode == 'pt' ? 'Editar' : 'Editar';
  String get productsCount => langCode == 'en' ? 'products' : langCode == 'pt' ? 'produtos' : 'productos';
  String get noCategories => langCode == 'en' ? 'No categories created.' : langCode == 'pt' ? 'Não há categorias criadas.' : 'No hay categorías creadas.';
  String get noProducts => langCode == 'en' ? 'No products in this category' : langCode == 'pt' ? 'Sem produtos nesta categoria' : 'Sin productos en esta categoría';
  String get about => langCode == 'en' ? 'About' : langCode == 'pt' ? 'Sobre' : 'Acerca de';
}

class MiListaComprasApp extends StatefulWidget {
  const MiListaComprasApp({super.key});

  @override
  State<MiListaComprasApp> createState() => _MiListaComprasAppState();
}

class _MiListaComprasAppState extends State<MiListaComprasApp> {
  final ValueNotifier<AppSettingsData> _settingsNotifier = ValueNotifier(
    AppSettingsData(themeMode: ThemeMode.light, isGridView: false, language: 'es'),
  );

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return AppSettings(
      notifier: _settingsNotifier,
      child: ValueListenableBuilder<AppSettingsData>(
        valueListenable: _settingsNotifier,
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mi Lista y Stock',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blueGrey,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: settings.themeMode,
            home: StreamBuilder(
              stream: _authService.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData) {
                  // Iniciamos la sincronización al autenticar
                  SyncService().startSync();
                  return const MainNavigatorScreen();
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

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String nameKey;

  @HiveField(1)
  String categoryKey;

  @HiveField(2)
  bool isToBuy;

  @HiveField(3)
  String? emoji;

  @HiveField(4)
  String? imagePath;

  @HiveField(5)
  bool isBuyScreen;

  Product({
    required this.nameKey,
    required this.categoryKey,
    this.isToBuy = true,
    this.emoji,
    this.imagePath,
    this.isBuyScreen = true,
  });
}

@HiveType(typeId: 1)
class CategoryItem extends HiveObject {
  @HiveField(0)
  String key;

  @HiveField(1)
  String? emoji;

  @HiveField(2)
  String? imagePath;

  CategoryItem({
    required this.key,
    this.emoji,
    this.imagePath,
  });
}

class MainNavigatorScreen extends StatefulWidget {
  const MainNavigatorScreen({super.key});

  @override
  State<MainNavigatorScreen> createState() => MainNavigatorScreenState();
}

class MainNavigatorScreenState extends State<MainNavigatorScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return ValueListenableBuilder<Box<CategoryItem>>(
      valueListenable: Hive.box<CategoryItem>('categoriesBox').listenable(),
      builder: (context, categoryBox, _) {
        return ValueListenableBuilder<Box<Product>>(
          valueListenable: Hive.box<Product>('productsBox').listenable(),
          builder: (context, productBox, _) {
            final categories = categoryBox.values.toList();

            // FILTRO DE UNICIDAD GLOBAL:
            // Esto elimina cualquier duplicado físico que haya en Hive de golpe
            final rawProducts = productBox.values.toList();
            final uniqueMap = <String, Product>{};
            for (var p in rawProducts) {
              final uniqueKey = '${p.categoryKey}_${p.nameKey.trim().toLowerCase()}_${p.isToBuy}';
              uniqueMap[uniqueKey] = p;
            }
            final products = uniqueMap.values.toList();

            final buyProductsCount = products.where((p) => p.isToBuy == true).length;
            final stockProductsCount = products.where((p) => p.isToBuy == false).length;

            return Scaffold(
              body: CategoryContainerScreen(
                isBuyScreen: _currentIndex == 0,
                products: products,
                categories: categories,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: [
                  NavigationDestination(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _currentIndex == 0 ? Colors.red.withValues(alpha: 0.25) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🛒', style: TextStyle(fontSize: 30)),
                        ),
                        if (buyProductsCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '$buyProductsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: t.navBuy,
                  ),
                  NavigationDestination(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _currentIndex == 1 ? Colors.green.withValues(alpha: 0.25) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🏠', style: TextStyle(fontSize: 30)),
                        ),
                        if (stockProductsCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '$stockProductsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: t.navStock,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userStatusText = "Cargando estado...";
  bool _isOwner = false; // Controla si es el dueño para mostrar la opción de compartir
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    final email = _authService.currentUserEmail;
    if (email != null) {
      final ownerEmail = await _authService.getOwnerForCollaborator(email);
      setState(() {
        if (ownerEmail != null) {
          _userStatusText = "Colaborador de: $ownerEmail";
          _isOwner = false; // Es colaborador, no puede invitar a otros
        } else {
          _userStatusText = "Dueño: $email";
          _isOwner = true; // Es el dueño, tiene privilegios administrativos
        }
      });
    } else {
      setState(() {
        _userStatusText = "No autenticado";
        _isOwner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final settingsNotifier = AppSettings.notifierOf(context);
    final t = AppLocalizations.of(context);

    // Textos adaptados para el menú lateral
    final String shareListTitle = settings.language == 'en' ? 'Share List' : settings.language == 'pt' ? 'Partilhar Lista' : 'Compartir Lista';
    final String shareListSub = settings.language == 'en' ? 'Add secondary user' : settings.language == 'pt' ? 'Adicionar utilizador secundário' : 'Añadir usuario secundario';
    final String managePermissionsTitle = settings.language == 'en' ? 'Manage Permissions' : settings.language == 'pt' ? 'Gerir Permissões' : 'Gestionar Permisos';
    final String managePermissionsSub = settings.language == 'en' ? 'Modify collaborator roles' : settings.language == 'pt' ? 'Modificar funções de colaboradores' : 'Modificar roles de colaboradores';
    final String logoutText = settings.language == 'en' ? 'Sign out' : settings.language == 'pt' ? 'Terminar sessão' : 'Cerrar sesión';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  '🛒 Mi Lista & Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userStatusText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Sección de Idioma
          ExpansionTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(t.language),
            subtitle: Text(
              settings.language == 'en'
                  ? 'English'
                  : settings.language == 'pt'
                  ? 'Português (Portugal)'
                  : 'Español',
            ),
            children: [
              RadioListTile<String>(
                title: const Text('Español'),
                value: 'es',
                groupValue: settings.language,
                onChanged: (val) {
                  if (val != null) settingsNotifier.value = settings.copyWith(language: val);
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: settings.language,
                onChanged: (val) {
                  if (val != null) settingsNotifier.value = settings.copyWith(language: val);
                },
              ),
              RadioListTile<String>(
                title: const Text('Português (Portugal)'),
                value: 'pt',
                groupValue: settings.language,
                onChanged: (val) {
                  if (val != null) settingsNotifier.value = settings.copyWith(language: val);
                },
              ),
            ],
          ),
          const Divider(),

          // Sección de Apariencia / Modo Oscuro y Vistas
          ExpansionTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(t.darkMode),
            subtitle: Text(t.darkMode),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.darkMode, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Switch(
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (isDark) {
                        settingsNotifier.value = settings.copyWith(
                          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.categoryView, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text(t.list),
                          icon: const Icon(Icons.view_list),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text(t.gallery),
                          icon: const Icon(Icons.grid_view),
                        ),
                      ],
                      selected: {settings.isGridView},
                      onSelectionChanged: (Set<bool> newSelection) {
                        settingsNotifier.value = settings.copyWith(
                          isGridView: newSelection.first,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),

          // Sección de Colaboradores (SOLO VISIBLE PARA EL DUEÑO)
          if (_isOwner) ...[
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: Text(shareListTitle),
              subtitle: Text(shareListSub),
              onTap: () {
                Navigator.pop(context); // Cierra el menú lateral
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    final emailController = TextEditingController();
                    String selectedRole = 'dynamic'; // Por defecto: Modo Dinámico

                    final dialogTitle = settings.language == 'en' ? 'Add Collaborator' : settings.language == 'pt' ? 'Adicionar Colaborador' : 'Añadir Colaborador';
                    final dialogContentDesc = settings.language == 'en'
                        ? 'Enter the secondary user\'s email and select their permission level:'
                        : settings.language == 'pt'
                        ? 'Introduza o email do utilizador secundário e selecione o nível de permissão:'
                        : 'Introduce el correo electrónico del usuario secundario y selecciona su nivel de permiso:';
                    final emailLabel = settings.language == 'en' ? 'Email address' : settings.language == 'pt' ? 'Correio eletrónico' : 'Correo electrónico';
                    final permissionLabel = settings.language == 'en' ? 'Permission Level:' : settings.language == 'pt' ? 'Nível de Permissão:' : 'Nivel de Permiso:';

                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          title: Text(dialogTitle),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dialogContentDesc),
                              const SizedBox(height: 16),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: emailLabel,
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.email),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                permissionLabel,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'full',
                                    child: Text(settings.language == 'en' ? 'Full Control' : settings.language == 'pt' ? 'Controlo Total' : 'Control Total'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'dynamic',
                                    child: Text(settings.language == 'en' ? 'Dynamic Mode (Move items)' : settings.language == 'pt' ? 'Modo Dinâmico (Mover itens)' : 'Modo Dinámico (Mover ítems)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'read',
                                    child: Text(settings.language == 'en' ? 'Read-only Mode' : settings.language == 'pt' ? 'Modo Leitura (Apenas ver)' : 'Modo Lectura (Solo ver)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setStateDialog(() {
                                      selectedRole = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(t.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final email = emailController.text.trim();
                                if (email.isNotEmpty) {
                                  try {
                                    final currentUser = FirebaseAuth.instance.currentUser;

                                    if (currentUser != null) {
                                      final collaboratorId = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(currentUser.uid)
                                          .collection('collaborators')
                                          .doc(collaboratorId)
                                          .set({
                                        'ownerEmail': currentUser.email,
                                        'collaboratorEmail': email,
                                        'permissionRole': selectedRole,
                                        'updatedAt': FieldValue.serverTimestamp(),
                                      }, SetOptions(merge: true));
                                    }

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(settings.language == 'en'
                                              ? 'Collaborator $email saved successfully!'
                                              : settings.language == 'pt'
                                              ? 'Colaborador $email guardado com sucesso!'
                                              : '¡Colaborador $email guardado con éxito!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${settings.language == 'en' ? 'Error saving: ' : settings.language == 'pt' ? 'Erro ao guardar: ' : 'Error al guardar: '}$e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              child: Text(t.save),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: Text(managePermissionsTitle),
              subtitle: Text(managePermissionsSub),
              onTap: () {
                Navigator.pop(context); // Cierra el Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageCollaboratorsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
          ],

          // Sección Acerca de
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t.about),
            subtitle: const Text('Versión 1.0.0'),
          ),
          const Divider(),

          // Botón de Cerrar Sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              logoutText,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              Navigator.pop(context); // Cierra el Drawer
              await _authService.signOut(); // Ejecuta el cierre de sesión

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
class CategoryContainerScreen extends StatefulWidget {
  final bool isBuyScreen;
  final List<Product> products;
  final List<CategoryItem> categories;

  const CategoryContainerScreen({
    super.key,
    required this.isBuyScreen,
    required this.products,
    required this.categories,
  });

  @override
  State<CategoryContainerScreen> createState() => _CategoryContainerScreenState();
}

class _CategoryContainerScreenState extends State<CategoryContainerScreen> with SingleTickerProviderStateMixin {
  bool _isFabOpen = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      value: _isFabOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _showAdvancedAddProductDialog(BuildContext context, {String? initialCategoryKey}) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        categories: widget.categories.map((c) => c.key).toList(),
        initialCategory: initialCategoryKey,
        isBuyScreen: widget.isBuyScreen,
      ),
    );
  }

  void _showAdvancedAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );
  }

  void _showEditCategoryDialog(BuildContext context, CategoryItem category) {
    final t = AppLocalizations.of(context);
    final nameController = TextEditingController(text: t.getCategoryName(category.key));
    String? selectedEmoji = category.emoji;
    String? imagePath = category.imagePath;
    final List<String> emojis = ['🍲', '🥩', '☕', '🥐', '🧀', '🍞', '🥞', '🥓',  '🍎', '🍌', '🥦', '🥔','🥂', '🍷', '🍺', '🧃', '🥛', '☕', '🫖', '🧽', '✨', '🧼', '🧻', '🧹', '🧺',  '📦', '🛒', '🏠', '💡', '🐾', '💊', '🍼', '🔋'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(t.editCategory),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(labelText: t.editCategory),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade700, width: 2),
                      ),
                      child: ClipOval(
                        child: imagePath != null
                            ? Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            : Center(
                          child: Text(
                            selectedEmoji ?? '📦',
                            style: const TextStyle(fontSize: 38),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.maxFinite,
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: emojis.length,
                      itemBuilder: (context, index) {
                        final emoji = emojis[index];
                        final isSelected = selectedEmoji == emoji && imagePath == null;

                        return SizedBox(
                          width: 65,
                          height: 65,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                setDialogState(() {
                                  selectedEmoji = emoji;
                                  imagePath = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                          if (image != null) {
                            setDialogState(() {
                              imagePath = image.path;
                              selectedEmoji = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Cámara'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (image != null) {
                            setDialogState(() {
                              imagePath = image.path;
                              selectedEmoji = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.image, size: 18),
                        label: const Text('Galería'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    String oldKey = category.key;
                    String newKey = nameController.text.trim();
                    category.key = newKey;
                    category.emoji = selectedEmoji;
                    category.imagePath = imagePath;
                    await category.save();

                    final productBox = Hive.box<Product>('productsBox');
                    for (var key in productBox.keys) {
                      final product = productBox.get(key);
                      if (product != null && product.categoryKey == oldKey) {
                        product.categoryKey = newKey;
                        await product.save();
                        await SyncService().syncProductUp(key.toString(), product);
                      }
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {});
                    }
                  }
                },
                child: Text(t.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryItem category) {
    final t = AppLocalizations.of(context);
    final localizedName = t.getCategoryName(category.key);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteCategory),
        content: Text('¿Deseas eliminar la categoría "$localizedName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final productBox = Hive.box<Product>('productsBox');
              final keysToDelete = <dynamic>[];

              for (var key in productBox.keys) {
                final product = productBox.get(key);
                if (product != null && product.categoryKey == category.key) {
                  keysToDelete.add(key);
                }
              }

              for (var key in keysToDelete) {
                await productBox.delete(key);
                await SyncService().syncProductDelete(key.toString());
              }

              await category.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(t.delete),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    final nameController = TextEditingController(text: product.nameKey);

    String? selectedEmoji = product.emoji ?? '📦';
    String? imagePath = product.imagePath;

    final List<String> emojis = ['🥛', '🍞', '🍎', '🍐', '🍊', '🍋', '🍉', '🍇', '🍓', '🫐', '🍒', '🥭','🍍', '🥥', '🥝', '🥑', '🥩', '☕', '🥐', '🧀', '🍌', '🍅', '🧻', '🧼', '🧊'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(t.edit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(labelText: t.edit),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade700, width: 2),
                      ),
                      child: ClipOval(
                        child: imagePath != null
                            ? Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            : Center(
                          child: Text(
                            selectedEmoji ?? '📦',
                            style: const TextStyle(fontSize: 38),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Personalización visual:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.maxFinite,
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: emojis.length,
                      itemBuilder: (context, index) {
                        final emoji = emojis[index];
                        final isSelected = (selectedEmoji == emoji) && (imagePath == null);

                        return SizedBox(
                          width: 65,
                          height: 65,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                setDialogState(() {
                                  selectedEmoji = emoji;
                                  imagePath = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                          if (image != null) {
                            setDialogState(() {
                              imagePath = image.path;
                              selectedEmoji = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Cámara'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (image != null) {
                            setDialogState(() {
                              imagePath = image.path;
                              selectedEmoji = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.image, size: 18),
                        label: const Text('Galería'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    product.nameKey = nameController.text.trim();
                    product.emoji = selectedEmoji;
                    product.imagePath = imagePath;
                    await product.save();

                    if (product.isInBox) {
                      final key = product.key.toString();
                      await SyncService().syncProductUp(key, product);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {});
                    }
                  }
                },
                child: Text(t.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.delete),
        content: Text('¿Deseas eliminar el producto "${product.nameKey}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (product.isInBox) {
                final key = product.key.toString();
                await product.delete();
                await SyncService().syncProductDelete(key);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(t.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final t = AppLocalizations.of(context);
    final title = widget.isBuyScreen ? t.buyTitle : t.stockTitle;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: widget.isBuyScreen ? Colors.red.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Transform.translate(
                offset: Offset(0, (1 - _expandAnimation.value) * 110),
                child: Opacity(
                  opacity: _expandAnimation.value,
                  child: Transform.scale(
                    scale: _expandAnimation.value,
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: FloatingActionButton.extended(
                        heroTag: 'btn_category',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueGrey.shade800,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        onPressed: () {
                          _toggleFab();
                          _showAdvancedAddCategoryDialog(context);
                        },
                        icon: const Text('📁', style: TextStyle(fontSize: 20)),
                        label: const Text(
                          'Nueva Categoría',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, (1 - _expandAnimation.value) * 55),
                child: Opacity(
                  opacity: _expandAnimation.value,
                  child: Transform.scale(
                    scale: _expandAnimation.value,
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: FloatingActionButton.extended(
                        heroTag: 'btn_product',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueGrey.shade800,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        onPressed: () {
                          _toggleFab();
                          _showAdvancedAddProductDialog(context);
                        },
                        icon: const Text('🛒', style: TextStyle(fontSize: 20)),
                        label: const Text(
                          'Nuevo Producto',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              FloatingActionButton(
                heroTag: 'btn_main',
                backgroundColor: widget.isBuyScreen ? Colors.red.shade700 : Colors.green.shade700,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                onPressed: _toggleFab,
                child: Transform.rotate(
                  angle: _expandAnimation.value * 0.785398,
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            ],
          );
        },
      ),
      body: widget.categories.isEmpty
          ? Center(
        child: Text(t.noCategories, style: const TextStyle(color: Colors.grey, fontSize: 16)),
      )
          : settings.isGridView
          ? GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.82,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final catItem = widget.categories[index];
          final localizedCategoryName = t.getCategoryName(catItem.key);
          final catProducts = widget.products.where((p) => p.categoryKey == catItem.key && p.isToBuy == widget.isBuyScreen).toList();

          final hasProducts = catProducts.isNotEmpty;
          final activeColor = widget.isBuyScreen ? Colors.red : Colors.green;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailScreen(
                      category: catItem,
                      isBuyScreen: widget.isBuyScreen,
                      products: widget.products,
                    ),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit, color: Colors.blueGrey),
                          title: Text('${t.edit} "$localizedCategoryName"'),
                          onTap: () {
                            Navigator.pop(context);
                            _showEditCategoryDialog(context, catItem);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: Text('${t.delete} "$localizedCategoryName"'),
                          onTap: () {
                            Navigator.pop(context);
                            _confirmDeleteCategory(context, catItem);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          // Aumentado el tamaño del contenedor del icono
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: hasProducts
                                ? activeColor.withValues(alpha: 0.25)
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: catItem.imagePath != null
                                ? Image.file(File(catItem.imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                : Center(
                              child: Text(
                                catItem.emoji ?? '📦',
                                // Aumentado el tamaño del emoji para que destaque más
                                style: const TextStyle(fontSize: 65),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      localizedCategoryName.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blueGrey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasProducts
                            ? activeColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${catProducts.length}',
                        style: TextStyle(
                          color: hasProducts ? activeColor.shade700 : Colors.grey,
                          fontSize: 13,
                          fontWeight: hasProducts ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final catItem = widget.categories[index];
          final localizedCategoryName = t.getCategoryName(catItem.key);
          final catProducts = widget.products.where((p) => p.categoryKey == catItem.key && p.isToBuy == widget.isBuyScreen).toList();

          return ExpandableCategoryCard(
            catItem: catItem,
            localizedCategoryName: localizedCategoryName,
            catProducts: catProducts,
            isBuyScreen: widget.isBuyScreen,
            t: t,
            onTapCard: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(
                    category: catItem,
                    isBuyScreen: widget.isBuyScreen,
                    products: widget.products,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            onLongPressCard: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit, color: Colors.blueGrey),
                        title: Text('${t.edit} "$localizedCategoryName"'),
                        onTap: () {
                          Navigator.pop(context);
                          _showEditCategoryDialog(context, catItem);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: Text('${t.delete} "$localizedCategoryName"'),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDeleteCategory(context, catItem);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            onEditProduct: _showEditProductDialog,
            onDeleteProduct: _confirmDeleteProduct,
          );
        },
      ),
    );
  }
}

class ExpandableCategoryCard extends StatefulWidget {
  final CategoryItem catItem;
  final String localizedCategoryName;
  final List<Product> catProducts;
  final bool isBuyScreen;
  final AppLocalizations t;
  final VoidCallback onTapCard;
  final VoidCallback onLongPressCard;
  final Function(BuildContext, Product) onEditProduct;
  final Function(BuildContext, Product) onDeleteProduct;

  const ExpandableCategoryCard({
    super.key,
    required this.catItem,
    required this.localizedCategoryName,
    required this.catProducts,
    required this.isBuyScreen,
    required this.t,
    required this.onTapCard,
    required this.onLongPressCard,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  @override
  State<ExpandableCategoryCard> createState() => _ExpandableCategoryCardState();
}

class _ExpandableCategoryCardState extends State<ExpandableCategoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasProducts = widget.catProducts.isNotEmpty;
    final activeColor = widget.isBuyScreen ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTapCard,
        onLongPress: widget.onLongPressCard,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: hasProducts
                          ? activeColor.withValues(alpha: 0.25)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: widget.catItem.imagePath != null
                          ? Image.file(File(widget.catItem.imagePath!), fit: BoxFit.cover)
                          : Center(
                        child: Text(
                          widget.catItem.emoji ?? '📦',
                          style: const TextStyle(fontSize: 45),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.localizedCategoryName.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasProducts
                                ? activeColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.catProducts.length} ${widget.t.productsCount}',
                            style: TextStyle(
                              color: hasProducts ? activeColor.shade700 : Colors.grey,
                              fontSize: 12,
                              fontWeight: hasProducts ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const Divider(height: 16),
                if (widget.catProducts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.t.noProducts,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.catProducts.length,
                    itemBuilder: (context, pIndex) {
                      final product = widget.catProducts[pIndex];
                      return Dismissible(
                        key: Key(product.key?.toString() ?? product.hashCode.toString()),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.swap_horiz, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            product.isToBuy = !product.isToBuy;
                            await product.save();
                            if (product.isInBox) {
                              await SyncService().syncProductUp(product.key.toString(), product);
                            }
                            return true;
                          } else {
                            bool? delete = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(widget.t.delete),
                                content: Text('¿Deseas eliminar el producto "${product.nameKey}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(widget.t.cancel),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(widget.t.delete),
                                  ),
                                ],
                              ),
                            );
                            if (delete == true) {
                              if (product.isInBox) {
                                final key = product.key.toString();
                                await product.delete();
                                await SyncService().syncProductDelete(key);
                              } else {
                                await product.delete();
                              }
                              return true;
                            }
                            return false;
                          }
                        },
                        child: InkWell(
                          onLongPress: () => widget.onEditProduct(context, product),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(shape: BoxShape.circle),
                              child: ClipOval(
                                child: product.imagePath != null
                                    ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                                    : Center(
                                  child: Text(
                                    product.emoji ?? (widget.isBuyScreen ? '🛒' : '📦'),
                                    style: const TextStyle(fontSize: 35),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              product.nameKey,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryDetailScreen extends StatefulWidget {
  final CategoryItem category;
  final bool isBuyScreen;
  final List<Product> products; // Mantenemos el parámetro por compatibilidad si se requiere

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.isBuyScreen,
    required this.products,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  // Ya no necesitamos _currentProducts como variable de estado global inicializada solo en el initState

  List<Product> _getFilteredProducts() {
    // Leemos directamente de la caja de Hive para tener siempre los datos en tiempo real
    final productBox = Hive.box<Product>('productsBox');
    final rawList = productBox.values
        .where((p) => p.categoryKey == widget.category.key && p.isToBuy == widget.isBuyScreen)
        .toList();

    // Filtramos duplicados únicos basándonos en el nombre y categoría
    final uniqueMap = <String, Product>{};
    for (var product in rawList) {
      final uniqueKey = '${product.categoryKey}_${product.nameKey.trim().toLowerCase()}_${product.isToBuy}';
      uniqueMap[uniqueKey] = product;
    }

    return uniqueMap.values.toList();
  }

  void _showProductOptionsBottomSheet(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueGrey),
              title: Text('${t.edit} "${product.nameKey}"'),
              onTap: () {
                Navigator.pop(context);
                _showEditProductDialog(context, product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('${t.delete} "${product.nameKey}"'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteProduct(context, product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    final nameController = TextEditingController(text: product.nameKey);
    String? selectedEmoji = product.emoji ?? '📦';
    String? imagePath = product.imagePath;
    final List<String> emojis = ['🥛', '🍞', '🍎', '🍐', '🍊', '🍋', '🍉', '🍇', '🍓', '🫐', '🍒', '🥭','🍍', '🥥', '🥝', '🥑', '🥩', '☕', '🥐', '🧀', '🍌', '🍅', '🧻', '🧼', '🧊'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(t.edit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(labelText: t.edit),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade700, width: 2),
                      ),
                      child: ClipOval(
                        child: imagePath != null
                            ? Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            : Center(
                          child: Text(
                            selectedEmoji ?? '📦',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Personalización visual:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.maxFinite,
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: emojis.length,
                      itemBuilder: (context, index) {
                        final emoji = emojis[index];
                        final isSelected = (selectedEmoji == emoji) && (imagePath == null);

                        return SizedBox(
                          width: 65,
                          height: 65,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                setDialogState(() {
                                  selectedEmoji = emoji;
                                  imagePath = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                          if (image != null) {
                            setDialogState(() {
                              imagePath = image.path;
                              selectedEmoji = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Cámara'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (image != null) {
                            setDialogState(() {
                              imagePath = image.path;
                              selectedEmoji = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.image, size: 18),
                        label: const Text('Galería'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    product.nameKey = nameController.text.trim();
                    product.emoji = selectedEmoji;
                    product.imagePath = imagePath;
                    await product.save();

                    if (product.isInBox) {
                      await SyncService().syncProductUp(product.key.toString(), product);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {});
                    }
                  }
                },
                child: Text(t.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, Product product) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.delete),
        content: Text('¿Deseas eliminar el producto "${product.nameKey}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (product.isInBox) {
                final productName = product.nameKey.trim();
                await product.delete();
                await SyncService().syncProductDelete(productName);
              } else {
                await product.delete();
              }
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: Text(t.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final t = AppLocalizations.of(context);
    final localizedName = t.getCategoryName(widget.category.key);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizedName.toUpperCase()),
        backgroundColor: widget.isBuyScreen ? Colors.red.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      // Envolvemos el cuerpo con un ValueListenableBuilder para que reaccione al instante a los cambios de Hive
      body: ValueListenableBuilder<Box<Product>>(
        valueListenable: Hive.box<Product>('productsBox').listenable(),
        builder: (context, productBox, _) {
          final currentProducts = _getFilteredProducts();

          if (currentProducts.isEmpty) {
            return Center(
              child: Text(
                t.noProducts,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return settings.isGridView
              ? GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: currentProducts.length,
            itemBuilder: (context, index) {
              final product = currentProducts[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    product.isToBuy = !product.isToBuy;
                    await product.save();
                    if (product.isInBox) {
                      await SyncService().syncProductUp(product.key.toString(), product);
                    }
                    setState(() {});
                  },
                  onLongPress: () => _showProductOptionsBottomSheet(context, product),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: ClipOval(
                              child: product.imagePath != null
                                  ? Image.file(File(product.imagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                  : FittedBox(
                                fit: BoxFit.contain,
                                child: Text(
                                  product.emoji ?? (widget.isBuyScreen ? '🛒' : '🏠'),
                                  style: const TextStyle(fontSize: 50),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.nameKey,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: currentProducts.length,
            itemBuilder: (context, index) {
              final product = currentProducts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Dismissible(
                  key: Key(product.key.toString() + product.nameKey),
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.swap_horiz, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      product.isToBuy = !product.isToBuy;
                      await product.save();
                      if (product.isInBox) {
                        await SyncService().syncProductUp(product.key.toString(), product);
                      }
                      setState(() {});
                      return false;
                    } else {
                      bool? delete = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(t.delete),
                          content: Text('¿Deseas eliminar el producto "${product.nameKey}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(t.cancel),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(t.delete),
                            ),
                          ],
                        ),
                      );
                      if (delete == true) {
                        if (product.isInBox) {
                          final productName = product.nameKey.trim();
                          await product.delete();
                          await SyncService().syncProductDelete(productName);
                        } else {
                          await product.delete();
                        }
                        setState(() {});
                        return true;
                      }
                      return false;
                    }
                  },
                  child: InkWell(
                    onTap: () async {
                      product.isToBuy = !product.isToBuy;
                      await product.save();
                      if (product.isInBox) {
                        await SyncService().syncProductUp(product.key.toString(), product);
                      }
                      setState(() {});
                    },
                    onLongPress: () => _showProductOptionsBottomSheet(context, product),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: product.imagePath != null
                              ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                              : Center(
                            child: Text(
                              product.emoji ?? (widget.isBuyScreen ? '🛒' : '🏠'),
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        product.nameKey,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.isBuyScreen ? Colors.red.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddProductDialog(
              categories: [widget.category.key],
              initialCategory: widget.category.key,
              isBuyScreen: widget.isBuyScreen,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddProductDialog extends StatefulWidget {
  final List<String> categories;
  final String? initialCategory;
  final bool isBuyScreen;

  const AddProductDialog({
    super.key,
    required this.categories,
    this.initialCategory,
    required this.isBuyScreen,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  late TextEditingController _nameController;
  late String _selectedCategory;
  String? _selectedEmoji;
  String? _imagePath;

  final List<String> _emojis = ['🥛', '🍞', '🍎', '🍐', '🍊', '🍋', '🍉', '🍇', '🍓', '🫐', '🍒', '🥭','🍍', '🥥', '🥝', '🥑', '🥩', '☕', '🥐', '🧀', '🍌', '🍅', '🧻', '🧼', '🧊'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedCategory = widget.initialCategory ?? (widget.categories.isNotEmpty ? widget.categories.first : '');
    _selectedEmoji = _emojis.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _selectedEmoji = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    bool categoryExists = widget.categories.contains(_selectedCategory);
    if (!categoryExists && widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }

    return AlertDialog(
      title: Text(t.add),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.add,
                hintText: 'Ej. Queso',
              ),
            ),
            const SizedBox(height: 16),
            if (widget.categories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: InputDecoration(labelText: t.categoryView.split(' ').first),
                items: widget.categories.map((catKey) {
                  return DropdownMenuItem(
                    value: catKey,
                    child: Text(t.getCategoryName(catKey)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
            const SizedBox(height: 16),
            Text('Personalización visual:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade700, width: 2),
                ),
                child: ClipOval(
                  child: _imagePath != null
                      ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                      : Center(
                    child: Text(
                      _selectedEmoji ?? '🏠',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.maxFinite,
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  final isSelected = _selectedEmoji == emoji && _imagePath == null;

                  return SizedBox(
                    width: 65,
                    height: 65,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          setState(() {
                            _selectedEmoji = emoji;
                            _imagePath = null;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Cámara'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text('Galería'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            final trimmedName = _nameController.text.trim();
            if (trimmedName.isNotEmpty && _selectedCategory.isNotEmpty) {
              final productBox = Hive.box<Product>('productsBox');

              // 1. Limpiamos cualquier rastro previo idéntico en Hive para evitar duplicados fantasma por sincronización
              final keysToDelete = <dynamic>[];
              for (var key in productBox.keys) {
                final p = productBox.get(key);
                if (p != null &&
                    p.nameKey.trim().toLowerCase() == trimmedName.toLowerCase() &&
                    p.categoryKey == _selectedCategory &&
                    p.isToBuy == widget.isBuyScreen) {
                  keysToDelete.add(key);
                }
              }
              if (keysToDelete.isNotEmpty) {
                await productBox.deleteAll(keysToDelete);
              }

              // 2. Creamos y guardamos el producto único
              final newProduct = Product(
                nameKey: trimmedName,
                categoryKey: _selectedCategory,
                isBuyScreen: widget.isBuyScreen,
                isToBuy: widget.isBuyScreen,
                emoji: _selectedEmoji,
                imagePath: _imagePath,
              );

              final productKey = await productBox.add(newProduct);
              await SyncService().syncProductUp(productKey.toString(), newProduct);

              if (context.mounted) {
                Navigator.pop(context, true); // Devolvemos true para indicar que se creó con éxito
              }
            }
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late TextEditingController _nameController;
  String? _selectedEmoji;
  String? _imagePath;

  final List<String> _emojis = ['🍲', '🥩', '☕', '🥐', '🧀', '🍞', '🥞', '🥓',  '🍎', '🍌', '🥦', '🥔','🥂', '🍷', '🍺', '🧃', '🥛', '☕', '🫖', '🧽', '✨', '🧼', '🧻', '🧹', '🧺',  '📦', '🛒', '🏠', '💡', '🐾', '💊', '🍼', '🔋'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedEmoji = _emojis.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _selectedEmoji = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.addCategory),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.addCategory,
                hintText: 'Ej. Mascotas',
              ),
            ),
            const SizedBox(height: 16),
            Text('Personalización visual:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade700, width: 2),
                ),
                child: ClipOval(
                  child: _imagePath != null
                      ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                      : Center(
                    child: Text(
                      _selectedEmoji ?? '📦',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.maxFinite,
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  final isSelected = _selectedEmoji == emoji && _imagePath == null;

                  return SizedBox(
                    width: 65,
                    height: 65,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          setState(() {
                            _selectedEmoji = emoji;
                            _imagePath = null;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Cámara'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text('Galería'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_nameController.text.trim().isNotEmpty) {
              final categoryBox = Hive.box<CategoryItem>('categoriesBox');
              bool exists = categoryBox.values.any((c) => c.key.toLowerCase() == _nameController.text.trim().toLowerCase());
              if (!exists) {
                final newCategory = CategoryItem(
                  key: _nameController.text.trim(),
                  emoji: _selectedEmoji ?? '📦',
                  imagePath: _imagePath,
                );
                await categoryBox.add(newCategory);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: Text(t.save),
        ),      ],
    );
  }
}