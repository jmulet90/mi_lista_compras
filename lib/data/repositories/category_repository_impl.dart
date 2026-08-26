import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/failures.dart';
import '../../core/logger.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/repositories/collaborator_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_data_source.dart';
import '../datasources/category_remote_data_source.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({
    required this._local,
    required this._remote,
    required this._collaboratorRepository,
    this._logger = const AppLogger(),
  });

  final CategoryLocalDataSource _local;
  final CategoryRemoteDataSource _remote;
  final CollaboratorRepository _collaboratorRepository;
  final AppLogger _logger;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _syncSub;
  bool _syncing = false;

  @override
  Stream<List<CategoryItem>> watchAll() {
    return _local.watchAll().map((models) => models.map(_toEntity).toList());
  }

  @override
  Future<List<CategoryItem>> getAll() async {
    return _local.getAll().map(_toEntity).toList();
  }

  @override
  Future<bool> exists(String key) async => _local.exists(key);

  @override
  Future<void> add(CategoryItem category) async {
    try {
      await _local.add(CategoryModel.fromEntity(category));
    } catch (e) {
      throw CacheFailure('No se pudo crear la categoría: $e');
    }
    await _safeSyncUp(category);
  }

  @override
  Future<void> update({
    required String currentKey,
    required CategoryItem category,
  }) async {
    try {
      await _local.update(
        currentKey: currentKey,
        model: CategoryModel.fromEntity(category),
      );
    } catch (e) {
      throw CacheFailure('No se pudo actualizar la categoría: $e');
    }

    // Si cambió la clave, el documento con la clave vieja se retira.
    if (currentKey.trim().toLowerCase() !=
        category.key.trim().toLowerCase()) {
      await _safeDelete(currentKey);
    }
    await _safeSyncUp(category);
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _local.delete(key);
    } catch (e) {
      throw CacheFailure('No se pudo eliminar la categoría: $e');
    }
    await _safeDelete(key);
  }

  @override
  Future<void> startRemoteSync({bool fullRefresh = false}) async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _syncSub?.cancel();
      _syncSub = null;

      final access = await _collaboratorRepository.resolveMyAccess();
      if (access == null) return;

      if (access.isOwner) {
        await _pushLocalCategoriesToCloud(access.ownerEmail);
      } else if (fullRefresh) {
        try {
          final remoteCategories = await _remote.fetchAll(access.ownerEmail);
          await _local.replaceAll(remoteCategories);
        } catch (e) {
          _logger.error('Error trayendo foto inicial de categorías', e);
        }
      }

      _syncSub = _remote
          .watchCategories(access.ownerEmail)
          .listen(_applyRemoteChanges, onError: (Object e) {
        _logger.error('Error escuchando cambios remotos de categorías', e);
      });
    } finally {
      _syncing = false;
    }
  }

  /// Sube todas las categorías locales del owner a Firestore.
  /// Esto garantiza que las categorías que existían antes del sync
  /// estén disponibles para los colaboradores.
  Future<void> _pushLocalCategoriesToCloud(String ownerEmail) async {
    try {
      final localCategories = _local.getAll();
      for (final category in localCategories) {
        await _remote.upload(
          ownerEmail: ownerEmail,
          category: category,
        );
      }
    } catch (e) {
      _logger.error('Error subiendo categorías locales a la nube', e);
    }
  }

  void _applyRemoteChanges(QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (final change in snapshot.docChanges) {
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          final data = change.doc.data();
          if (data == null) break;
          final key = data['key'] as String? ?? '';
          if (key.trim().isEmpty) break;
          _local.put(CategoryModel(
            key: key,
            emoji: data['emoji'] as String?,
            imagePath: data['imagePath'] as String?,
          ));
          break;
        case DocumentChangeType.removed:
          final data = change.doc.data();
          if (data == null) {
            _local.delete(change.doc.id);
            break;
          }
          final key = data['key'] as String? ?? change.doc.id;
          if (key.isNotEmpty) {
            _local.delete(key);
          }
          break;
      }
    }
  }

  Future<void> _safeSyncUp(CategoryItem category) async {
    try {
      final access = await _collaboratorRepository.resolveMyAccess();
      if (access == null || !access.canFullyEdit) return;
      await _remote.upload(
        ownerEmail: access.ownerEmail,
        category: CategoryModel.fromEntity(category),
      );
    } catch (e) {
      // La sincronización es best-effort; el cambio local ya quedó guardado.
      _logger.error('Error al subir categoría a la nube', e);
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      final access = await _collaboratorRepository.resolveMyAccess();
      if (access == null || !access.canFullyEdit) return;
      await _remote.deleteDoc(ownerEmail: access.ownerEmail, key: key);
    } catch (e) {
      _logger.error('Error al eliminar categoría en la nube', e);
    }
  }

  CategoryItem _toEntity(CategoryModel model) => model.toEntity();
}
