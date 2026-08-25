import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

/// Acceso a Firestore para la colección de productos del dueño.
class ProductRemoteDataSource {
  ProductRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _productsRef(String ownerEmail) {
    return _db.collection('users_data').doc(ownerEmail).collection('products');
  }

  CollectionReference<Map<String, dynamic>> _imagesRef(String ownerEmail) {
    return _db
        .collection('users_data')
        .doc(ownerEmail)
        .collection('product_images');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProducts(
    String ownerEmail,
  ) {
    return _productsRef(ownerEmail).snapshots();
  }

  /// Foto completa del estado remoto (para el arranque de un colaborador).
  Future<List<ProductModel>> fetchAll(String ownerEmail) async {
    final snapshot = await _productsRef(ownerEmail).get();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> upload({
    required String ownerEmail,
    required Map<String, dynamic> data,
  }) async {
    final docId = (data['nameKey'] as String).trim();
    await _productsRef(ownerEmail).doc(docId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDoc({
    required String ownerEmail,
    required String id,
  }) async {
    await _productsRef(ownerEmail).doc(id).delete();
  }

  /// Sube los bytes (base64) de la foto del producto. El documento remoto
  /// queda identificado por [imageId] para que otros dispositivos sepan si
  /// necesitan descargarla.
  Future<void> uploadImage({
    required String ownerEmail,
    required String imageId,
    required String base64Data,
  }) async {
    await _imagesRef(ownerEmail).doc(imageId).set({
      'data': base64Data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Devuelve los bytes (base64) de la imagen o null si no existe.
  Future<String?> fetchImage({
    required String ownerEmail,
    required String imageId,
  }) async {
    final doc = await _imagesRef(ownerEmail).doc(imageId).get();
    final data = doc.data();
    return data?['data'] as String?;
  }

  Future<void> deleteImage({
    required String ownerEmail,
    required String imageId,
  }) async {
    await _imagesRef(ownerEmail).doc(imageId).delete();
  }
}
