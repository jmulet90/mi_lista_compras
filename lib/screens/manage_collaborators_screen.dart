import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCollaboratorsScreen extends StatelessWidget {
  const ManageCollaboratorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Colaboradores'),
      ),
      body: currentUserId == null
          ? const Center(child: Text('Usuario no autenticado'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('collaborators')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No tienes colaboradores añadidos todavía.'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final email = data['collaboratorEmail'] ?? 'Sin correo';
              final currentRole = data['permissionRole'] ?? 'read';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.blueGrey),
                  title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Permiso: ${_getRoleDescription(currentRole)}'),
                  ),
                  trailing: DropdownButton<String>(
                    value: currentRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'full',
                        child: Text('Control Total'),
                      ),
                      DropdownMenuItem(
                        value: 'dynamic',
                        child: Text('Modo Dinámico'),
                      ),
                      DropdownMenuItem(
                        value: 'read',
                        child: Text('Modo Lectura'),
                      ),
                    ],
                    onChanged: (newRole) async {
                      if (newRole != null && newRole != currentRole) {
                        // Actualiza el rol directamente en Firestore de forma instantánea
                        await docs[index].reference.update({
                          'permissionRole': newRole,
                        });
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'full':
        return 'Control Total';
      case 'dynamic':
        return 'Modo Dinámico';
      case 'read':
        return 'Solo Lectura';
      default:
        return 'Desconocido';
    }
  }
}