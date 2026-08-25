import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/logger.dart';

/// Escucha la concesión manual de premium desde Firestore.
///
/// Colección: `premium_users/{email}` con campo `premium: true` (boolean).
/// La escritura se hace a mano desde la consola de Firebase; la app solo lee,
/// de modo que la propietaria decide a qué emails se les activa premium.
class PremiumRemoteDataSource {
  PremiumRemoteDataSource(this._db, {this.logger = const AppLogger()});

  final FirebaseFirestore _db;
  final AppLogger logger;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  /// El ID del documento SIEMPRE es el email en minúsculas y sin espacios.
  static String docId(String email) => email.trim().toLowerCase();

  /// Tolerante con el tipo del campo: acepta booleano true y texto "true"
  /// (la consola de Firebase crea los campos como string por defecto).
  static bool _grantedFrom(Map<String, dynamic>? data) {
    final value = data?['premium'];
    return value == true || value?.toString().toLowerCase() == 'true';
  }

  /// Notifica cambios del documento del [email]; sin sesión notifica false.
  void watch({
    required String? email,
    required void Function(bool granted) onChanged,
  }) {
    _sub?.cancel();
    _sub = null;
    if (email == null || email.isEmpty) {
      onChanged(false);
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
      onChanged(snapshot.exists && _grantedFrom(snapshot.data()));
    }, onError: (Object e) {
      logger.error('Premium: error leyendo $docPath', e);
      onChanged(false);
    });
  }

  /// Verifica si un email tiene premium en Firestore (lectura única).
  Future<bool> checkPremium(String email) async {
    try {
      final doc = await _db
          .collection('premium_users')
          .doc(docId(email))
          .get();
      return doc.exists && _grantedFrom(doc.data());
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
