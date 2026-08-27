import 'dart:async';

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
import '../domain/usecases/reset_password.dart';
import '../domain/usecases/restore_premium.dart';
import '../domain/usecases/sign_in.dart';
import '../domain/usecases/sign_in_with_google.dart';
import '../domain/usecases/sign_up.dart';
import '../domain/usecases/toggle_product.dart';
import '../domain/usecases/update_product.dart';
import 'di.dart';
import 'session_status.dart';

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
  // Garantiza que la sesión persistida sobreviva a los reinicios de la app
  // (arranques en frío). En Android el valor por defecto ya es LOCAL, pero
  // fijarlo explícitamente evita regresiones si cambia la configuración.
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (_) {}
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
        deletedKeys: initializer.deletedProductKeys,
      ));
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(
        local: categoryLocal,
        remote: sl<CategoryRemoteDataSource>(),
        collaboratorRepository: collaboratorRepository,
        deletedKeys: initializer.deletedCategoryKeys,
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
  sl.registerLazySingleton(
      () => ResetPasswordUseCase(sl<AuthRepository>()));
  CrashOverlay.log('DI services registered, initializing PremiumRepository...');
  try {
    await sl<PremiumRepository>().init();
    CrashOverlay.log('PremiumRepository initialized');
  } catch (e, st) {
    CrashOverlay.logError('Error inicializando PremiumRepository', e, st);
    const AppLogger().error('Error inicializando PremiumRepository', e);
  }

  CrashOverlay.log('Setting up session status notifier...');
  final sessionStatus = SessionStatusNotifier();
  sl.registerLazySingleton<SessionStatusNotifier>(() => sessionStatus);
  CrashOverlay.log('Setting up auth state watcher...');
  _watchAuthState(initializer, sessionStatus);
  CrashOverlay.log('bootstrap() completed');
}

/// Cuenta cuyos datos están cargados localmente (null = sin sesión).
String? _loadedOwner;
bool _syncRunning = false;

/// Reacciona a inicios, cambios y cierres de sesión: limpia los datos
/// locales del usuario anterior y carga los de la cuenta nueva, o los
/// valores por defecto si es su primer arranque.
void _watchAuthState(
    AppInitializer initializer, SessionStatusNotifier sessionStatus) {
  CrashOverlay.log('Watching auth state changes...');

  // Arranque en frío: si hay una sesión guardada se espera a que Firebase la
  // restaure sin mostrar el login; si no hay sesión, directo al login.
  sessionStatus.value = initializer.lastAuthUid == null
      ? AppSessionPhase.unauthenticated
      : AppSessionPhase.loading;

  // Margen de seguridad: si Firebase no restaura la sesión en frío en unos
  // segundos, se entra igualmente con la cuenta de la sesión local (cuyos
  // datos siguen en Hive). Nunca un splash infinito ni un login falso.
  Timer(const Duration(milliseconds: 2500), () {
    final phase = sessionStatus.value;
    if ((phase == AppSessionPhase.loading ||
            phase == AppSessionPhase.authenticatedLoadingData) &&
        initializer.lastAuthUid != null) {
      sessionStatus.value = AppSessionPhase.ready;
    }
  });

  FirebaseAuth.instance.authStateChanges().listen((user) async {
    try {
      print('[AW] auth: ${user?.uid ?? "null"}; cur=${FirebaseAuth.instance.currentUser?.uid ?? "null"}');
      CrashOverlay.log('Auth state changed: ${user?.uid ?? "null (logged out)"}');
      final previousOwner = _loadedOwner;
      final previousUid = initializer.lastAuthUid;

      // Persistir la sesión local en cuanto hay un usuario: es lo que
      // permite saltar el login en el arranque en frío y reabrir directo
      // en la misma cuenta.
      if (user != null) {
        await initializer.setLastAuthUid(user.uid);
        // La sesión ya se confirmó: pasar a cargar sus datos.
        if (sessionStatus.value == AppSessionPhase.loading ||
            sessionStatus.value == AppSessionPhase.unauthenticated) {
          sessionStatus.value = AppSessionPhase.authenticatedLoadingData;
        }
      }

      final access = await sl<CollaboratorRepository>().resolveMyAccess();
      final owner = access?.ownerEmail.trim().toLowerCase();

      // Logout real: había una sesión cargada, el stream emite null y Firebase
      // ya no tiene usuario en memoria. No es un arranque en frío (ahí
      // `previousOwner` es null cuando llega el primer evento null) ni un null
      // transitorio del refresco de sesión (donde currentUser sigue vivo), así
      // que solo aquí se limpia la sesión local y los datos del anterior.
      if (user == null &&
          previousOwner != null &&
          FirebaseAuth.instance.currentUser == null) {
        await initializer.setLastAuthUid(null);
        await initializer.clearUserData();
        _loadedOwner = null;
        _syncRunning = false;
        sessionStatus.value = AppSessionPhase.unauthenticated;
        return;
      }

      // Arranque en frío que restaura una cuenta DISTINTA a la que dejó los
      // datos locales (p. ej. se cambió de cuenta en otro dispositivo): limpiar
      // antes de sincronizar para que no se mezclen los datos de dos cuentas.
      if (user != null && previousUid != null && user.uid != previousUid) {
        await initializer.clearUserData();
        await initializer.seedIfEmpty();
      }

      // Misma cuenta ya cargada en este proceso, o arranque frío con la misma
      // cuenta: solo garantizar que la escucha esté activa.
      if (user != null && owner != null && owner == previousOwner) {
        if (!_syncRunning) await _startSync();
        return;
      }

      // Cambio de cuenta real dentro del mismo proceso (no arranque frío,
      // donde previousOwner es null): limpiar los datos locales del usuario
      // anterior y sembrar los defaults para la cuenta nueva.
      if (user != null &&
          previousOwner != null &&
          owner != null &&
          owner != previousOwner) {
        await initializer.clearUserData();
        await initializer.seedIfEmpty();
      }

      _loadedOwner = owner;
      _syncRunning = false;

      if (user == null || owner == null) {
        // Firebase no confirmó sesión (p. ej. restauración lenta) pero hay una
        // sesión local guardada: entrar con los datos locales de esa cuenta.
        if (sessionStatus.value == AppSessionPhase.loading &&
            initializer.lastAuthUid != null) {
          sessionStatus.value = AppSessionPhase.ready;
        }
        return;
      }

      // Foto completa de la nube para esta cuenta...
      await _startSync(fullRefresh: true);
    } catch (e, st) {
      CrashOverlay.logError('Error al cambiar de cuenta', e, st);
      const AppLogger().error('Error al cambiar de cuenta', e);
    }
  });
}

/// Arranca la sincronización bidireccional (reiniciable por cuenta).
Future<void> _startSync({bool fullRefresh = false}) async {
  // Primera carga de la cuenta: la app muestra el splash mientras llegan los
  // datos. Las re-sincronizaciones de una cuenta ya lista no cambian la fase.
  final sessionStatus = sl<SessionStatusNotifier>();
  if (sessionStatus.value == AppSessionPhase.loading ||
      sessionStatus.value == AppSessionPhase.unauthenticated) {
    sessionStatus.value = AppSessionPhase.authenticatedLoadingData;
  }

  sl<CollaboratorRepository>().invalidateAccessCache();
  final access = await sl<CollaboratorRepository>().resolveMyAccess();
  CrashOverlay.log('[_startSync] access=${access != null ? "owner=${access.ownerEmail} isOwner=${access.isOwner}" : "NULL"}');

  // Productos y categorías se sincronizan en paralelo para reducir el tiempo.
  await Future.wait([
    sl<ProductRepository>().startRemoteSync(fullRefresh: fullRefresh),
    sl<CategoryRepository>().startRemoteSync(fullRefresh: fullRefresh),
  ]);
  _syncRunning = true;
  sessionStatus.value = AppSessionPhase.ready;
  CrashOverlay.log('[_startSync] DONE');
}
