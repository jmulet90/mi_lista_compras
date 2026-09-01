import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/failures.dart';
import '../../core/logger.dart';
import '../../core/utils/image_storage.dart';

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
    required Box<String> deletedKeys,
    AppLogger logger = const AppLogger(),
  })  : _local = local,
        _remote = remote,
        _collaboratorRepository = collaboratorRepository,
        _deletedKeys = deletedKeys,
        _logger = logger;

  final ProductLocalDataSource _local;
  final ProductRemoteDataSource _remote;
  final CollaboratorRepository _collaboratorRepository;
  final Box<String> _deletedKeys;
  final AppLogger _logger;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _syncSub;
  Timer? _imageRetryTimer;
  Timer? _syncRetryTimer;
  String? _activeOwnerEmail;
  bool _syncing = false;

  @override
  Future<void> startRemoteSync({bool fullRefresh = false}) async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _syncSub?.cancel();
      _syncSub = null;
      _syncRetryTimer?.cancel();
      _syncRetryTimer = null;
      _imageRetryTimer?.cancel();
      _imageRetryTimer = null;

      final access = await _collaboratorRepository.resolveMyAccess();
      if (access == null) return;

      _activeOwnerEmail = access.ownerEmail;

      if (access.isOwner) {
        if (fullRefresh) {
          try {
            final remoteProducts = await _remote.fetchAll(access.ownerEmail);
            final remoteKeys = {
              for (final p in remoteProducts) p.nameKey.trim().toLowerCase()
            };

            // 1. Resolve tombstones: delete from Firestore any product
            //    the user intentionally removed, then clear the tombstone.
            //    Track which keys were tombstoned so the merge skips them.
            final tombstonedKeys = <String>{};
            for (final key in _deletedKeys.values.toList()) {
              final keyLower = key.trim().toLowerCase();
              tombstonedKeys.add(keyLower);
              if (remoteKeys.contains(keyLower)) {
                await _remote.deleteDoc(
                    ownerEmail: access.ownerEmail, id: keyLower);
              }
              await _deletedKeys.delete(key);
            }

            // 2. Merge: add remote products that are missing locally
            //    (added on another device). Do NOT import products that
            //    were intentionally deleted (in tombstonedKeys).
            final localKeys = {
              for (final m in _local.getAll()) m.nameKey.trim().toLowerCase()
            };
            for (final remote in remoteProducts) {
              final key = remote.nameKey.trim().toLowerCase();
              if (!localKeys.contains(key) && !tombstonedKeys.contains(key)) {
                await _local.put(remote, key: key);
              }
            }

            // 3. Push local-only products to remote (created offline).
            final localProducts = _local.getAll();
            for (final model in localProducts) {
              if (!remoteKeys.contains(model.nameKey.trim().toLowerCase())) {
                await _remote.upload(
                    ownerEmail: access.ownerEmail, data: model.toMap());
              }
            }
          } catch (e) {
            _logger.error('Error trayendo productos remotos del owner', e);
          }
        } else {
          await _pushLocalProductsToCloud(access.ownerEmail);
        }
      } else if (fullRefresh) {
        try {
          final remoteProducts = await _remote.fetchAll(access.ownerEmail);
          await _local.replaceAll(remoteProducts);
        } catch (e) {
          _logger.error('Error trayendo foto inicial de productos', e);
        }
      }

      // Descarga las fotos que faltan en disco (primer arranque de un
      // colaborador o imágenes pendientes de reintentos anteriores).
      unawaited(_hydrateMissingImages(access.ownerEmail));

      _subscribeToRemote(access.ownerEmail);
    } finally {
      _syncing = false;
    }
  }

  /// Mantiene la escucha en vivo de los productos del owner. Si Firestore
  /// pierde la suscripción (p. ej. por un error de red transitorio), se
  /// reprograma con reintentos para no dejar la sincronización muerta.
  void _subscribeToRemote(String ownerEmail) {
    _syncSub?.cancel();
    _syncSub = _remote
        .watchProducts(ownerEmail)
        .listen(_applyRemoteChanges, onError: (Object e) {
      _logger.error('Error escuchando cambios remotos de productos', e);
      _scheduleSyncRetry(ownerEmail);
    });
  }

  void _scheduleSyncRetry(String ownerEmail) {
    _syncRetryTimer?.cancel();
    _syncRetryTimer = Timer(const Duration(seconds: 5), () {
      _subscribeToRemote(ownerEmail);
    });
  }

  /// Sube todos los productos locales del owner a Firestore.
  /// Esto garantiza que los productos que existían antes del sync
  /// estén disponibles para los colaboradores.
  Future<void> _pushLocalProductsToCloud(String ownerEmail) async {
    try {
      final localProducts = _local.getAll();
      for (final model in localProducts) {
        await _remote.upload(ownerEmail: ownerEmail, data: model.toMap());
      }
    } catch (e) {
      _logger.error('Error subiendo productos locales a la nube', e);
    }
  }

  Future<void> _applyRemoteChanges(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    final ownerEmail = _activeOwnerEmail;

    for (final change in snapshot.docChanges) {
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          final data = change.doc.data();
          if (data == null) continue;
          final model = ProductModel.fromMap(data);
          if (model.nameKey.trim().isEmpty) continue;
          final key = model.nameKey.trim().toLowerCase();

          // Skip products the user intentionally deleted.
          if (_deletedKeys.containsKey(key)) {
            try {
              final access =
                  await _collaboratorRepository.resolveMyAccess();
              if (access != null && access.canFullyEdit) {
                await _remote.deleteDoc(
                    ownerEmail: access.ownerEmail, id: key);
              }
            } catch (_) {}
            continue;
          }

          await _mergeImageState(model, existing: _local.getByKey(key),
              ownerEmail: ownerEmail);

          // La clave única en Hive es el nameKey limpio.
          await _local.put(model, key: key);
          break;
        case DocumentChangeType.removed:
          await _local.deleteByKey(change.doc.id);
          break;
      }
    }
  }

  /// Resuelve el estado de la imagen de [model] contra el registro local:
  /// descarga fotos nuevas de la nube y conserva el archivo local cuando la
  /// imagen remota es la misma (los bytes nunca viajan en el doc del producto).
  Future<void> _mergeImageState(
    ProductModel model, {
    required ProductModel? existing,
    required String? ownerEmail,
  }) async {
    if (_sameImageId(model.imageId, existing?.imageId)) {
      // Misma imagen (o ninguna): conservar el archivo ya descargado.
      model.imagePath = _validLocalPath(existing);
      return;
    }

    if (model.imageId != null && ownerEmail == null) {
      // Sesión todavía sin resolver: conservar lo que haya localmente.
      model.imagePath = _validLocalPath(existing);
      return;
    }

    if (model.imageId != null) {
      // Foto nueva o actualizada en la nube: descargarla.
      final saved = await _downloadImage(ownerEmail!, model.imageId!);
      if (saved != null) {
        model.imagePath = saved;
        return;
      }
      // Fallo temporal: se reintenta luego. Mientras tanto no se pisa el
      // imageId local para que el próximo evento vuelva a intentarlo y se
      // sigue mostrando la foto anterior si existe.
      if (existing != null) {
        model.imageId = existing.imageId;
      }
      model.imagePath = _validLocalPath(existing);
      _scheduleImageRetry(ownerEmail);
      return;
    }

    // model.imageId == null: la foto fue quitada en un dispositivo autorizado.
    model.imagePath = null;
  }

  String? _validLocalPath(ProductModel? model) {
    final path = model?.imagePath;
    if (path == null || path.isEmpty) return null;
    return File(path).existsSync() ? path : null;
  }

  bool _sameImageId(String? a, String? b) => a == b;

  Future<String?> _downloadImage(String ownerEmail, String imageId) async {
    try {
      final base64Data =
          await _remote.fetchImage(ownerEmail: ownerEmail, imageId: imageId);
      if (base64Data == null || base64Data.isEmpty) return null;
      return await persistImageBytes(
        base64Decode(base64Data),
        name: '$imageId.jpg',
      );
    } catch (e) {
      _logger.error('Error al descargar imagen de producto', e);
      return null;
    }
  }

  /// Descarga todas las fotos referenciadas que falten en disco.
  Future<void> _hydrateMissingImages(String ownerEmail) async {
    for (final model in _local.getAll()) {
      final imageId = model.imageId;
      if (imageId == null) continue;
      if (_validLocalPath(model) != null) continue;
      try {
        final saved = await _downloadImage(ownerEmail, imageId);
        if (saved != null) {
          model.imagePath = saved;
          await _local.put(model, key: model.nameKey.trim().toLowerCase());
        }
      } catch (_) {
        // Best-effort: los reintentos o el siguiente evento lo cubrirán.
      }
    }
  }

  void _scheduleImageRetry(String ownerEmail) {
    _imageRetryTimer?.cancel();
    _imageRetryTimer = Timer(const Duration(seconds: 20), () {
      unawaited(_hydrateMissingImages(ownerEmail));
    });
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
  Future<void> upsert(Product product, {String? previousId}) async {
    final key = product.id.trim().toLowerCase();

    await _deletedKeys.delete(key);
    final existing = _local.getByKey(key);
    final model = ProductModel.fromEntity(product);

    // La imagen solo se sube cuando cambió el archivo; toggles y ediciones
    // de texto reutilizan el mismo imageId.
    final pathChanged = existing?.imagePath != model.imagePath;
    String? removedImageId;
    if (pathChanged) {
      if (model.imagePath != null) {
        model.imageId = _generateImageId();
      } else {
        removedImageId = existing?.imageId;
        model.imageId = null;
      }
    } else {
      model.imageId = existing?.imageId;
    }

    try {
      await _local.put(model, key: key);
    } catch (e) {
      throw CacheFailure('No se pudo guardar el producto: $e');
    }

    await _safeSyncUp(model, imageChanged: pathChanged, removedImageId: removedImageId);

    if (previousId != null &&
        previousId.trim().toLowerCase() != key.toLowerCase()) {
      await _safeDelete(previousId.trim());
    }
  }

  String _generateImageId() {
    final rnd = Random.secure();
    final suffix = List.generate(4, (_) => rnd.nextInt(16)).join();
    return 'img_${DateTime.now().microsecondsSinceEpoch}_$suffix';
  }

  @override
  Future<void> deleteById(String id) async {
    final docId = id.trim().toLowerCase();
    final existing = _local.getByKey(docId);
    final imageId = existing?.imageId;

    // Record tombstone so sync doesn't resurrect this product.
    await _deletedKeys.put(docId, docId);

    try {
      await _local.deleteByKey(docId);
    } catch (e) {
      throw CacheFailure('No se pudo eliminar el producto: $e');
    }

    try {
      final access = await _collaboratorRepository.resolveMyAccess();
      if (access == null || !access.canFullyEdit) return;
      await _remote.deleteDoc(ownerEmail: access.ownerEmail, id: docId);
      if (imageId != null) {
        await _remote.deleteImage(
            ownerEmail: access.ownerEmail, imageId: imageId);
      }
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

  Future<void> _safeSyncUp(
    ProductModel model, {
    required bool imageChanged,
    String? removedImageId,
  }) async {
    try {
      final access = await _collaboratorRepository.resolveMyAccess();
      if (access == null || !access.canMoveItems) return;
      final ownerEmail = access.ownerEmail;

      await _remote.upload(ownerEmail: ownerEmail, data: model.toMap());

      if (imageChanged && model.imagePath != null) {
        final file = File(model.imagePath!);
        if (await file.exists()) {
          final base64Data = base64Encode(await file.readAsBytes());
          await _remote.uploadImage(
            ownerEmail: ownerEmail,
            imageId: model.imageId!,
            base64Data: base64Data,
          );
        }
      }

      if (removedImageId != null) {
        await _remote.deleteImage(ownerEmail: ownerEmail, imageId: removedImageId);
      }
    } catch (e) {
      // La sincronización con la nube es best-effort: el cambio local ya
      // quedó guardado y se propagará en el próximo arranque o edición.
      _logger.error('Error al sincronizar producto con la nube', e);
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      final keyLower = key.trim().toLowerCase();
      final access = await _collaboratorRepository.resolveMyAccess();
      if (access == null || !access.canFullyEdit) return;
      await _deletedKeys.put(keyLower, keyLower);
      await _remote.deleteDoc(ownerEmail: access.ownerEmail, id: keyLower);
    } catch (e) {
      _logger.error('Error al eliminar producto antiguo de la nube', e);
    }
  }

  Product _toEntity(ProductModel model) => model.toEntity();
}
