class Collaborator {
  const Collaborator({
    required this.email,
    required this.role,
    this.docId = '',
  });

  final String email;
  final String role;

  /// ID real del documento en Firestore. Operar siempre sobre este ID
  /// evita duplicados con documentos creados bajo esquemas antiguos.
  final String docId;
}
