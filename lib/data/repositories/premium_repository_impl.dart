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
/// - Guarda el plan por cuenta en settingsBox para funcionar offline.
/// - En builds debug permite un override local para probar los límites
///   sin tener los productos publicados en Play Console (cicla libre →
///   Premium → Premium Plus → libre).
/// - Además, acepta concesiones manuales por email desde Firestore
///   (`premium_users/{email}`, campo `tier`), gestionadas desde la consola.
class PremiumRepositoryImpl implements PremiumRepository {
  PremiumRepositoryImpl(this._billing, this._settingsBox, this._remote,
      {this.onPremiumChanged});

  static const String _legacyPurchasedKey = 'premium_unlocked';
  static const String _legacyDebugKey = 'debug_premium_override';
  static const String _purchasedPrefix = 'premium_unlocked_';
  static const String _plusPurchasedPrefix = 'premium_plus_unlocked_';
  static const String _debugPrefix = 'debug_premium_override_';
  static const String _plusDebugPrefix = 'debug_plus_override_';
  static const String _legacyRemoteKeyPrefix = 'remote_premium_';
  static const String _tierKeyPrefix = 'remote_tier_';

  final BillingDataSource _billing;
  final Box<dynamic> _settingsBox;
  final PremiumRemoteDataSource _remote;
  final void Function(bool isPremium)? onPremiumChanged;

  final _controller = StreamController<PremiumStatus>.broadcast();

  PremiumStatus _status = const PremiumStatus();
  List<ProductDetails> _products = const [];
  Completer<AppTier>? _purchaseCompleter;
  StreamSubscription<User?>? _authSub;
  bool _started = false;
  AppTier _remoteTier = AppTier.free;

  /// Email (minúsculas) de la cuenta cuyos flags se leen/escriben.
  /// Así el plan nunca se filtra entre cuentas del mismo dispositivo.
  String? _accountKey;

  bool _readFlag(String prefix) {
    final key = _accountKey;
    if (key == null) return false;
    return _settingsBox.get('$prefix$key') as bool? ?? false;
  }

  AppTier get _cachedTier {
    if (_readFlag(_plusPurchasedPrefix)) return AppTier.premiumPlus;
    if (_readFlag(_purchasedPrefix)) return AppTier.premium;
    return AppTier.free;
  }

  AppTier get _debugTier {
    if (!kDebugMode) return AppTier.free;
    if (_readFlag(_plusDebugPrefix)) return AppTier.premiumPlus;
    if (_readFlag(_debugPrefix)) return AppTier.premium;
    return AppTier.free;
  }

  AppTier get _tierNow {
    var tier = _cachedTier;
    if (_debugTier.value > tier.value) tier = _debugTier;
    if (_remoteTier.value > tier.value) tier = _remoteTier;
    return tier;
  }

  String _tierKey(String email) =>
      '$_tierKeyPrefix${email.trim().toLowerCase()}';

  AppTier _readTierKey(String email) {
    final stored = _settingsBox.get(_tierKey(email))?.toString().toLowerCase();
    if (stored == 'plus' || stored == 'premiumplus') {
      return AppTier.premiumPlus;
    }
    if (stored == 'premium') return AppTier.premium;
    return AppTier.free;
  }

  AppTier _tierForProductId(String productId) =>
      productId == PremiumRepository.premiumPlusId
          ? AppTier.premiumPlus
          : AppTier.premium;

  Future<void> _setPurchasedFlag(AppTier tier) async {
    final key = _accountKey;
    if (key == null) return;
    if (tier.isPremiumPlus) {
      await _settingsBox.put('$_plusPurchasedPrefix$key', true);
    } else {
      await _settingsBox.put('$_purchasedPrefix$key', true);
    }
  }

  void _emit(PremiumStatus status) {
    final tier = _tierNow;
    final effective = status.copyWith(tier: tier);
    debugPrint(
      '[INFO] PremiumRepo emit: tier=${effective.tier.name} '
      'cached=${_cachedTier.name} debug=${_debugTier.name} '
      'remote=${_remoteTier.name}',
    );
    final changed = _status.tier != effective.tier;
    _status = effective;
    _controller.add(effective);
    if (changed) onPremiumChanged?.call(effective.isPremium);
  }

  @override
  Future<void> init() async {
    if (_started) return;
    _started = true;

    _emit(_status);

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
    final key = _accountKey;
    if (key != null) {
      if (_settingsBox.get(_legacyPurchasedKey) as bool? ?? false) {
        await _settingsBox.put('$_purchasedPrefix$key', true);
      }
      await _settingsBox.delete(_legacyPurchasedKey);
      if (_settingsBox.containsKey(_legacyDebugKey)) {
        final legacy = _settingsBox.get(_legacyDebugKey) as bool? ?? false;
        await _settingsBox.put('$_debugPrefix$key', legacy);
        await _settingsBox.delete(_legacyDebugKey);
      }
      // Migración: concesión remota booleana (premium) → campo tier.
      final oldGrant = _settingsBox.get('$_legacyRemoteKeyPrefix$key');
      if (oldGrant == true || oldGrant?.toString().toLowerCase() == 'true') {
        await _settingsBox.put(_tierKey(key), 'premium');
      }
      await _settingsBox.delete('$_legacyRemoteKeyPrefix$key');
    }

    _remoteTier =
        _accountKey == null ? AppTier.free : _readTierKey(_accountKey!);
    _emit(_status);

    _remote.watch(email: user?.email, onChanged: (tier, exists) async {
      debugPrint(
        '[INFO] Premium cb: tier=${tier.name} exists=$exists cuenta=$_accountKey '
        'remote=$_remoteTier',
      );
      final key = _accountKey;
      if (key == null) return;
      final changed = tier != _remoteTier;
      _remoteTier = tier;

      // Firebase es la autoridad: si el documento existe y dice "sin plan",
      // apaga también los flags locales (compra cacheadas) y de debug para
      // que un `false` deje realmente al usuario sin plan.
      if (exists && tier == AppTier.free) {
        debugPrint('[INFO] Premium: revocación remota -> limpiando flags de $key');
        await _settingsBox.put('$_purchasedPrefix$key', false);
        await _settingsBox.put('$_plusPurchasedPrefix$key', false);
        await _settingsBox.put('$_debugPrefix$key', false);
        await _settingsBox.put('$_plusDebugPrefix$key', false);
      }

      if (changed) {
        debugPrint('[INFO] Premium: concesión remota=${tier.name} para $key');
        switch (tier) {
          case AppTier.premium:
            await _settingsBox.put(_tierKey(key), 'premium');
            break;
          case AppTier.premiumPlus:
            await _settingsBox.put(_tierKey(key), 'plus');
            break;
          case AppTier.free:
            await _settingsBox.delete(_tierKey(key));
            break;
        }
      }
      _emit(_status);
    });
  }

  Future<void> _refreshStoreInfo() async {
    try {
      if (!await _billing.isAvailable()) return;
      final details = await _billing.queryProducts({
        PremiumRepository.productId,
        PremiumRepository.premiumPlusId,
      });
      if (details.isEmpty) return;
      _products = details;
      String? premiumPrice;
      String? plusPrice;
      for (final product in details) {
        if (product.id == PremiumRepository.productId) {
          premiumPrice = product.price;
        } else if (product.id == PremiumRepository.premiumPlusId) {
          plusPrice = product.price;
        }
      }
      _emit(_status.copyWith(
        priceText: premiumPrice,
        priceTextPlus: plusPrice,
      ));
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
          await _setPurchasedFlag(_tierForProductId(purchase.productID));
          _emit(_status.copyWith(pending: false));
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
        completer.complete(_tierNow);
      }
      _purchaseCompleter = null;
    }
  }

  @override
  Future<bool> purchase(AppTier tier) async {
    if (_tierNow.value >= tier.value) return true;
    final targetId = tier.isPremiumPlus
        ? PremiumRepository.premiumPlusId
        : PremiumRepository.productId;
    try {
      var details = _products;
      if (details.isEmpty) {
        if (!await _billing.isAvailable()) return false;
        details = await _billing.queryProducts({
          PremiumRepository.productId,
          PremiumRepository.premiumPlusId,
        });
        _products = details;
      }
      ProductDetails? product;
      for (final candidate in details) {
        if (candidate.id == targetId) {
          product = candidate;
          break;
        }
      }
      if (product == null) {
        _emit(_status.copyWith(pending: false));
        return false;
      }

      _purchaseCompleter = Completer<AppTier>();
      _emit(_status.copyWith(pending: true));
      await _billing.buy(product);
      final confirmed = await _purchaseCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => _tierNow,
      );
      return confirmed.value >= tier.value;
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
    final premiumKey = '$_debugPrefix$_accountKey';
    final plusKey = '$_plusDebugPrefix$_accountKey';
    if (_debugTier.isPremiumPlus) {
      // Premium Plus actual → volver a libre.
      await _settingsBox.delete(premiumKey);
      await _settingsBox.delete(plusKey);
    } else if (_debugTier.isPremium) {
      // Premium actual → subir a Premium Plus.
      await _settingsBox.put(plusKey, true);
    } else {
      // Libre → activar Premium.
      await _settingsBox.put(premiumKey, true);
    }
    _emit(_status);
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