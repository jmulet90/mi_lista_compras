import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/entities/collaborator.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/collaborator_repository.dart';
import '../localization/app_localizations.dart';

class ManageCollaboratorsScreen extends StatelessWidget {
  const ManageCollaboratorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = sl<AuthRepository>().currentUser;
    final collaboratorRepository = sl<CollaboratorRepository>();
    final ownerEmail = currentUser?.email;
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.manageCollaborators),
      ),
      body: ownerEmail == null
          ? Center(child: Text(t.notAuthenticated))
          : StreamBuilder<List<Collaborator>>(
              stream:
                  collaboratorRepository.watchCollaborators(ownerEmail),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final collaborators =
                    snapshot.data ?? const <Collaborator>[];

                if (collaborators.isEmpty) {
                  return Center(
                    child: Text(t.noCollaborators),
                  );
                }

                return ListView.builder(
                  itemCount: collaborators.length,
                  itemBuilder: (context, index) {
                    final collaborator = collaborators[index];
                    final email = collaborator.email;
                    final currentRole = collaborator.role;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, color: Colors.blueGrey),
                        title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('${t.permissionPrefix} ${_getRoleDescription(t, currentRole)}'),
                        ),
                        trailing: DropdownButton<String>(
                          value: currentRole,
                          items: [
                            DropdownMenuItem(
                              value: 'full',
                              child: Text(t.roleFull),
                            ),
                            DropdownMenuItem(
                              value: 'dynamic',
                              child: Text(t.roleDynamic),
                            ),
                            DropdownMenuItem(
                              value: 'read',
                              child: Text(t.roleRead),
                            ),
                          ],
                          onChanged: (newRole) async {
                            if (newRole != null && newRole != currentRole) {
                              try {
                                await collaboratorRepository.updateRole(
                                  ownerEmail: ownerEmail,
                                  collaboratorEmail: email,
                                  role: newRole,
                                );
                              } on Failure catch (failure) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(failure.message)),
                                  );
                                }
                              }
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

  String _getRoleDescription(AppLocalizations t, String role) {
    switch (role) {
      case 'full':
        return t.roleFull;
      case 'dynamic':
        return t.roleDynamic;
      case 'read':
        return t.roleRead;
      default:
        return t.roleUnknown;
    }
  }
}
