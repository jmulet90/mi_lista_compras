import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/bootstrap/app_initializer.dart';
import '../data/datasources/billing_data_source.dart';
import '../data/datasources/category_remote_data_source.dart';
import '../data/datasources/collaborator_remote_data_source.dart';
import '../data/datasources/premium_remote_data_source.dart';
import '../data/datasources/product_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/category_repository_impl.dart';
import '../data/repositories/collaborator_repository_impl.dart';
import '../data/repositories/premium_repository_impl.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/collaborator_repository.dart';
import '../domain/repositories/premium_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/services/access_guard.dart';
import 'utils/product_asset_catalog.dart';
import '../core/crash_overlay.dart';
import '../core/logger.dart';
import '../domain/usecases/add_category.dart';
import '../domain/usecases/add_product.dart';
import '../domain/usecases/check_premium.dart';
import '../domain/usecases/delete_category.dart';
import '../domain/usecases/delete_product.dart';
import '../domain/usecases/purchase_premium.dart';
import '../domain/usecases/rename_category.dart';
import '../domain/usecases/restore_premium.dart';
import '../domain/usecases/sign_in.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/sign_up.dart';
import '../domain/usecases/toggle_product.dart';
import '../domain/usecases/update_product.dart';
import 'di.dart';

/// Inicializa los datos locales y registra todas las dependencias.
///
/// Debe llamarse después de [WidgetsFlutterBinding.ensureInitialized].
Future<void> bootstrap() async {
  CrashOverlay.log('bootstrap() started');
  final initializer = AppInitializer();
  await initializer.initialize();
  CrashOverlay.log('Asset catalog loading...');
  await ProductAssetCatalog.instance.ensureLoaded();
  CrashOverlay.log('Asset catalog loaded');

  final productLocal = initializer.products;
  final categoryLocal = initializer.categories;

  CrashOverlay.log('Registering DI services...');
  sl.registerLazySingleton<AppInitializer>(() => initializer);
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSource(FirebaseFirestore.instance),
  );
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSource(FirebaseFirestore.instance),
  );
  sl.registerLazySingleton<CollaboratorRemoteDataSource>(
    () => CollaboratorRemoteDataSource(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(FirebaseAuth.instance),
  );
  sl.registerLazySingleton(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(
      () => SignInWithGoogleUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<CollaboratorRepository>(
    () => CollaboratorRepositoryImpl(sl<CollaboratorRemoteDataSource>()),
  );

  final collaboratorRepository = sl<CollaboratorRepository>();

  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(
        local: productLocal,
        remote: sl<ProductRemoteDataSource>(),
        collaboratorRepository: collaboratorRepository,
      ));
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(
        local: categoryLocal,
        remote: sl<CategoryRemoteDataSource>(),
        collaboratorRepository: collaboratorRepository,
      ));

  sl.registerLazySingleton(() => AccessGuard(collaboratorRepository));
  final guard = sl<AccessGuard>();

  sl.registerLazySingleton(
      () => AddProductUseCase(sl<ProductRepository>(), guard));
  sl.registerLazySingleton(
      () => UpdateProductUseCase(sl<ProductRepository>(), guard));
  sl.registerLazySingleton(
      () => ToggleProductUseCase(sl<ProductRepository>(), guard));
  sl.registerLazySingleton(
      () => DeleteProductUseCase(sl<ProductRepository>(), guard));
  sl.registerLazySingleton(
      () => AddCategoryUseCase(sl<CategoryRepository>(), guard));
  sl.registerLazySingleton(() => RenameCategoryUseCase(
        sl<CategoryRepository>(),
        sl<ProductRepository>(),
        guard,
      ));
  sl.registerLazySingleton(() => DeleteCategoryUseCase(
        sl<CategoryRepository>(),
        sl<ProductRepository>(),
        guard,
      ));

  sl.registerLazySingleton<BillingDataSource>(() => BillingDataSource());
  sl.registerLazySingleton<PremiumRemoteDataSource>(
    () => PremiumRemoteDataSource(FirebaseFirestore.instance),
  );
  sl.registerLazySingleton<PremiumRepository>(
    () => PremiumRepositoryImpl(
      sl<BillingDataSource>(),
      initializer.settings,
      sl<PremiumRemoteDataSource>(),
      onPremiumChanged: (isPremium) {
        sl<CollaboratorRepository>().syncOwnerPremium(isPremium: isPremium);
      },
    ),
  );
  sl.registerLazySingleton(() => CheckPremiumUseCase(sl<PremiumRepository>()));
  sl.registerLazySingleton(
      () => PurchasePremiumUseCase(sl<PremiumRepository>()));
  sl.registerLazySingleton(
      () => RestorePurchasesUseCase(sl<PremiumRepository>()));
  CrashOverlay.log('DI services registered, initializing PremiumRepository...');
  try {
    await sl<PremiumRepository>().init();
    CrashOverlay.log('PremiumRepository initialized');
  } catch (e, st) {
    CrashOverlay.logError('Error inicializando PremiumRepository', e, st);
    const AppLogger().error('Error inicializando PremiumRepository', e);
  }

  CrashOverlay.log('Setting up auth state watcher...');
  _watchAuthState(initializer);
  CrashOverlay.log('bootstrap() completed');
}

/// Cuenta cuyos datos están cargados localmente (null = sin sesión).
String? _loadedOwner;
bool _syncRunning = false;

/// Reacciona a inicios, cambios y cierres de sesión: limpia los datos
/// locales del usuario anterior y carga los de la cuenta nueva, o los
/// valores por defecto si es su primer arranque.
void _watchAuthState(AppInitializer initializer) {
  CrashOverlay.log('Watching auth state changes...');
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    try {
      CrashOverlay.log('Auth state changed: ${user?.uid ?? "null (logged out)"}');
      final access = await sl<CollaboratorRepository>().resolveMyAccess();
      final owner = access?.ownerEmail.trim().toLowerCase();

      // Misma cuenta ya cargada: solo garantizar que la escucha esté activa.
      if (owner != null && owner == _loadedOwner) {
        if (!_syncRunning) await _startSync();
        return;
      }

      _loadedOwner = owner;
      _syncRunning = false;

      // Cambio de cuenta o cierre de sesión: partir de un estado limpio.
      await initializer.clearUserData();

      if (owner == null) return;

      // Foto completa de la nube para esta cuenta...
      await _startSync(fullRefresh: true);
      // ...y valores por defecto solo si no tenía nada guardado.
      await initializer.seedIfEmpty();
    } catch (e, st) {
      CrashOverlay.logError('Error al cambiar de cuenta', e, st);
      const AppLogger().error('Error al cambiar de cuenta', e);
    }
  });
}

/// Arranca la sincronización bidireccional (reiniciable por cuenta).
Future<void> startSync() => _startSync();

Future<void> _startSync({bool fullRefresh = false}) async {
  await sl<ProductRepository>().startRemoteSync(fullRefresh: fullRefresh);
  await sl<CategoryRepository>().startRemoteSync(fullRefresh: fullRefresh);
  _syncRunning = true;
}
