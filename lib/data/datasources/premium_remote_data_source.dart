import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/logger.dart';
import '../../domain/entities/premium_status.dart';

/// Escucha la concesión manual de planes desde Firestore.
///
/// Colección: `premium_users/{email}`:
/// - campo `tier`: "premium" o "plus" (recomendado), o
/// - campo `premium: true` (compatibilidad) → plan Premium.
/// La escritura se hace a mano desde la consola de Firebase; la app solo lee,
/// de modo que la propietaria decide qué emails activan cada plan.
class PremiumRemoteDataSource {
  PremiumRemoteDataSource(this._db, {this.logger = const AppLogger()});

  final FirebaseFirestore _db;
  final AppLogger logger;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  /// El ID del documento SIEMPRE es el email en minúsculas y sin espacios.
  static String docId(String email) => email.trim().toLowerCase();

  /// Determina el plan desde los campos del documento. Tolerante con los
  /// tipos: acepta "plus"/"premium" en texto y booleanos true.
  static AppTier _tierFrom(Map<String, dynamic>? data) {
    final tier =
        data?['tier']?.toString().trim().toLowerCase().replaceAll('_', '');
    if (tier == 'plus' || tier == 'premiumplus') {
      return AppTier.premiumPlus;
    }
    if (tier == 'premium') return AppTier.premium;
    if (data?['premiumPlus'] == true ||
        data?['premiumPlus']?.toString().toLowerCase() == 'true') {
      return AppTier.premiumPlus;
    }
    if (data?['premium'] == true ||
        data?['premium']?.toString().toLowerCase() == 'true') {
      return AppTier.premium;
    }
    return AppTier.free;
  }

  /// Notifica cambios del documento del [email]; sin sesión notifica free
  /// con `exists=false`. [exists] indica si el documento `premium_users`
  /// existe (para que el repositorio distinga "revocado" de "sin concesión").
  void watch({
    required String? email,
    required void Function(AppTier tier, bool exists) onChanged,
  }) {
    _sub?.cancel();
    _sub = null;
    if (email == null || email.isEmpty) {
      onChanged(AppTier.free, false);
      return;
    }

    final docPath = 'premium_users/${docId(email)}';
    logger.info('Premium: escuchando $docPath ...');
    _sub = _db
        .collection('premium_users')
        .doc(docId(email))
        .snapshots()
        .listen((snapshot) {
      logger.info(
        'Premium: $docPath -> existe=${snapshot.exists} datos=${snapshot.data()}',
      );
      onChanged(
        snapshot.exists ? _tierFrom(snapshot.data()) : AppTier.free,
        snapshot.exists,
      );
    }, onError: (Object e) {
      logger.error('Premium: error leyendo $docPath', e);
      onChanged(AppTier.free, false);
    });
  }

  /// Verifica el plan de un email en Firestore (lectura única).
  Future<AppTier> checkTier(String email) async {
    try {
      final doc = await _db
          .collection('premium_users')
          .doc(docId(email))
          .get();
      return doc.exists ? _tierFrom(doc.data()) : AppTier.free;
    } catch (_) {
      return AppTier.free;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}