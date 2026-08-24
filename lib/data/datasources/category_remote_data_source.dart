import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';

/// Acceso a Firestore para la colección de categorías del dueño.
class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _categoriesRef(String ownerEmail) {
    return _db
        .collection('users_data')
        .doc(ownerEmail)
        .collection('categories');
  }

  static String docId(String key) => Uri.encodeComponent(key.trim());

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCategories(
    String ownerEmail,
  ) {
    return _categoriesRef(ownerEmail).snapshots();
  }

  /// Foto completa del estado remoto (para el arranque de un colaborador).
  Future<List<CategoryModel>> fetchAll(String ownerEmail) async {
    final snapshot = await _categoriesRef(ownerEmail).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CategoryModel(
        key: data['key'] as String? ?? '',
        emoji: data['emoji'] as String?,
        imagePath: data['imagePath'] as String?,
      );
    }).toList();
  }

  Future<void> upload({
    required String ownerEmail,
    required CategoryModel category,
  }) async {
    await _categoriesRef(ownerEmail).doc(docId(category.key)).set({
      'key': category.key,
      'emoji': category.emoji,
      'imagePath': category.imagePath,
      if (category.key != docId(category.key)) 'docId': docId(category.key),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDoc({
    required String ownerEmail,
    required String key,
  }) async {
    await _categoriesRef(ownerEmail).doc(docId(key)).delete();
  }
}
