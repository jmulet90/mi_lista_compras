import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/entities/premium_status.dart';
import '../../domain/repositories/premium_repository.dart';
import '../datasources/billing_data_source.dart';
import '../datasources/premium_remote_data_source.dart';

/// Implementación de [PremiumRepository] sobre Google Play Billing.
///
/// - Escucha el stream de compras del sistema y completa las pendientes.
/// - Cachea el resultado en settingsBox para funcionar offline.
/// - En builds debug permite un override local para probar los límites
///   sin tener el producto publicado en Play Console.
/// - Además, acepta concesiones manuales por email desde Firestore
///   (`premium_users/{email}`), gestionadas desde la consola de Firebase.
class PremiumRepositoryImpl implements PremiumRepository {
  PremiumRepositoryImpl(this._billing, this._settingsBox, this._remote,
      {this.onPremiumChanged});

  static const String _legacyPurchasedKey = 'premium_unlocked';
  static const String _legacyDebugKey = 'debug_premium_override';
  static const String _purchasedPrefix = 'premium_unlocked_';
  static const String _debugPrefix = 'debug_premium_override_';

  final BillingDataSource _billing;
  final Box<dynamic> _settingsBox;
  final PremiumRemoteDataSource _remote;
  final void Function(bool isPremium)? onPremiumChanged;

  final _controller = StreamController<PremiumStatus>.broadcast();

  PremiumStatus _status = const PremiumStatus(isPremium: false);
  List<ProductDetails> _products = const [];
  Completer<bool>? _purchaseCompleter;
  StreamSubscription<User?>? _authSub;
  bool _started = false;
  bool _remotePremium = false;

  /// Email (minúsculas) de la cuenta cuyos flags se leen/escriben.
  /// Así el premium nunca se filtra entre cuentas del mismo dispositivo.
  String? _accountKey;

  bool _readFlag(String prefix) {
    final key = _accountKey;
    if (key == null) return false;
    return _settingsBox.get('$prefix$key') as bool? ?? false;
  }

  bool get _cachedFlag => _readFlag(_purchasedPrefix);

  bool get _debugOverride => kDebugMode && _readFlag(_debugPrefix);

  String _grantKey(String email) =>
      'remote_premium_${email.trim().toLowerCase()}';

  bool get _isPremiumNow => _cachedFlag || _debugOverride || _remotePremium;

  Future<void> _setPurchasedFlag(bool value) async {
    final key = _accountKey;
    if (key == null) return;
    await _settingsBox.put('$_purchasedPrefix$key', value);
  }

  void _emit(PremiumStatus status) {
    debugPrint(
      '[INFO] PremiumRepo emit: isPremium=${status.isPremium} '
      'cached=$_cachedFlag debug=$_debugOverride remote=$_remotePremium',
    );
    final changed = _status.isPremium != status.isPremium;
    _status = status;
    _controller.add(status);
    if (changed) onPremiumChanged?.call(status.isPremium);
  }

  @override
  Future<void> init() async {
    if (_started) return;
    _started = true;

    _emit(PremiumStatus(isPremium: _isPremiumNow));

    _billing.purchaseStream.listen(_onPurchaseUpdates);

    // Concesiones manuales por email (colección premium_users).
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen(_onUserChanged);

    unawaited(_refreshStoreInfo());
  }

  Future<void> _onUserChanged(User? user) async {
    final email = user?.email?.trim().toLowerCase();
    _accountKey = (email == null || email.isEmpty) ? null : email;

    // Migración única: flags globales de versiones anteriores pasan a la
    // cuenta actual y se retiran para no filtrarse entre usuarios.
    if (_accountKey != null) {
      if (_settingsBox.get(_legacyPurchasedKey) as bool? ?? false) {
        await _settingsBox.put('$_purchasedPrefix$_accountKey', true);
      }
      await _settingsBox.delete(_legacyPurchasedKey);
      if (_settingsBox.containsKey(_legacyDebugKey)) {
        final legacy = _settingsBox.get(_legacyDebugKey) as bool? ?? false;
        await _settingsBox.put('$_debugPrefix$_accountKey', legacy);
        await _settingsBox.delete(_legacyDebugKey);
      }
    }

    _remotePremium = _accountKey == null
        ? false
        : (_settingsBox.get(_grantKey(user!.email!)) as bool? ?? false);
    _emit(PremiumStatus(isPremium: _isPremiumNow));

    // Sincronizar premium con documentos de colaboradores al iniciar sesion.
    onPremiumChanged?.call(_isPremiumNow);

    _remote.watch(email: user?.email, onChanged: (granted) async {
      debugPrint(
        '[INFO] Premium cb: granted=$granted cuenta=$_accountKey '
        'remote=$_remotePremium',
      );
      final key = _accountKey;
      if (key == null || granted == _remotePremium) {
        debugPrint('[INFO] Premium cb: DESCARTADO por guard');
        return;
      }
      debugPrint('[INFO] Premium: concesión remota=$granted para $key');
      _remotePremium = granted;
      if (granted) {
        await _settingsBox.put(_grantKey(key), true);
      } else {
        await _settingsBox.delete(_grantKey(key));
      }
      _emit(_status.copyWith(isPremium: _isPremiumNow));
    });
  }

  Future<void> _refreshStoreInfo() async {
    try {
      if (!await _billing.isAvailable()) return;
      final details =
          await _billing.queryProduct(PremiumRepository.productId);
      if (details.isEmpty) return;
      _products = details;
      _emit(_status.copyWith(priceText: details.first.price));
    } catch (_) {
      // Sin tienda disponible (sideload/debug): precio por defecto en UI.
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> updates) async {
    var changed = false;
    for (final purchase in updates) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _setPurchasedFlag(true);
          _emit(_status.copyWith(isPremium: true, pending: false));
          changed = true;
          break;
        case PurchaseStatus.pending:
          _emit(_status.copyWith(pending: true));
          changed = true;
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _emit(_status.copyWith(pending: false));
          changed = true;
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await _billing.complete(purchase);
      }
    }
    if (changed) {
      final completer = _purchaseCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete(_status.isPremium);
      }
      _purchaseCompleter = null;
    }
  }

  @override
  Future<bool> purchase() async {
    if (_status.isPremium) return true;
    try {
      var details = _products;
      if (details.isEmpty) {
        if (!await _billing.isAvailable()) return false;
        details = await _billing.queryProduct(PremiumRepository.productId);
        _products = details;
      }
      ProductDetails? product;
      for (final candidate in details) {
        if (candidate.id == PremiumRepository.productId) {
          product = candidate;
          break;
        }
      }
      if (product == null) {
        _emit(_status.copyWith(pending: false));
        return false;
      }

      _purchaseCompleter = Completer<bool>();
      _emit(_status.copyWith(pending: true));
      await _billing.buy(product);
      return await _purchaseCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => _status.isPremium,
      );
    } catch (_) {
      _emit(_status.copyWith(pending: false));
      return false;
    }
  }

  @override
  Future<void> restore() => _billing.restore();

  @override
  Future<void> toggleDebugOverride() async {
    if (!kDebugMode || _accountKey == null) return;
    final key = '$_debugPrefix$_accountKey';
    final next = !(_settingsBox.get(key) as bool? ?? false);
    await _settingsBox.put(key, next);
    _emit(_status.copyWith(isPremium: _isPremiumNow));
  }

  @override
  PremiumStatus current() => _status;

  @override
  Stream<PremiumStatus> watch() async* {
    yield _status;
    yield* _controller.stream;
  }

  void dispose() {
    _authSub?.cancel();
    _remote.dispose();
    _controller.close();
  }
}
