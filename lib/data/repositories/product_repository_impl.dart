import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/failures.dart';
import '../../core/logger.dart';

// Los constructores usan parámetros con nombre descriptivos en las llamadas.
// ignore_for_file: prefer_initializing_formals
import '../../domain/entities/product.dart';
import '../../domain/repositories/collaborator_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required ProductLocalDataSource local,
    required ProductRemoteDataSource remote,
    required CollaboratorRepository collaboratorRepository,
    AppLogger logger = const AppLogger(),
  })  : _local = local,
        _remote = remote,
        _collaboratorRepository = collaboratorRepository,
        _logger = logger;

  final ProductLocalDataSource _local;
  final ProductRemoteDataSource _remote;
  final CollaboratorRepository _collaboratorRepository;
  final AppLogger _logger;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _syncSub;

  @override
  Future<void> startRemoteSync({bool fullRefresh = false}) async {
    await _syncSub?.cancel();
    _syncSub = null;

    final access = await _collaboratorRepository.resolveMyAccess();
    if (access == null) return;

    // Foto completa del estado remoto al entrar como colaborador o tras un
    // cambio de cuenta: evita mezclar datos locales del usuario anterior.
    if (!access.isOwner || fullRefresh) {
      try {
        final remoteProducts = await _remote.fetchAll(access.ownerEmail);
        await _local.replaceAll(remoteProducts);
      } catch (e) {
        _logger.error('Error trayendo foto inicial de productos', e);
      }
    }

    _syncSub = _remote
        .watchProducts(access.ownerEmail)
        .listen(_applyRemoteChanges, onError: (Object e) {
      _logger.error('Error escuchando cambios remotos de productos', e);
    });
  }

  void _applyRemoteChanges(QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (final change in snapshot.docChanges) {
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          final data = change.doc.data();
          if (data == null) continue;
          final model = ProductModel.fromMap(data);
          if (model.nameKey.trim().isEmpty) continue;
          // La clave única en Hive es el nameKey limpio.
          _local.put(model, key: model.nameKey.trim());
          break;
        case DocumentChangeType.removed:
          _local.deleteByKey(change.doc.id);
          break;
      }
    }
  }

  @override
  Stream<List<Product>> watchAll() {
    return _local.watchAll().map((models) => models.map(_toEntity).toList());
  }

  @override
  Future<List<Product>> getAll() async {
    return _local.getAll().map(_toEntity).toList();
  }

  @override
  Future<void> upsert(Product product) async {
    try {
      await _local.put(ProductModel.fromEntity(product));
    } catch (e) {
      throw CacheFailure('No se pudo guardar el producto: $e');
    }

    await _safeSyncUp(product);
  }

  @override
  Future<void> deleteById(String id) async {
    final docId = id.trim();

    try {
      await _local.deleteByKey(docId);
    } catch (e) {
      throw CacheFailure('No se pudo eliminar el producto: $e');
    }

    try {
      final access = await _collaboratorRepository.resolveMyAccess();
      if (access == null || !access.canMoveItems) return;
      await _remote.deleteDoc(ownerEmail: access.ownerEmail, id: docId);
    } catch (e) {
      _logger.error('Error al eliminar producto de la nube', e);
    }
  }

  @override
  Future<void> deleteWhere(bool Function(Product product) test) async {
    try {
      await _local.deleteWhere((model) => test(_toEntity(model)));
    } catch (e) {
      throw CacheFailure('No se pudo limpiar el almacén local: $e');
    }
  }

  Future<void> _safeSyncUp(Product product) async {
    try {
      final access = await _collaboratorRepository.resolveMyAccess();
      if (access == null || !access.canMoveItems) return;
      await _remote.upload(
        ownerEmail: access.ownerEmail,
        data: ProductModel.fromEntity(product).toMap(),
      );
    } catch (e) {
      // La sincronización con la nube es best-effort: el cambio local ya
      // quedó guardado y se propagará en el próximo arranque o edición.
      _logger.error('Error al subir producto a la nube', e);
    }
  }

  Product _toEntity(ProductModel model) => model.toEntity();
}
