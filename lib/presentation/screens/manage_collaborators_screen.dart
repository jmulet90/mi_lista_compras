import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di.dart';
import '../../core/failures.dart';
import '../../domain/entities/collaborator.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/collaborator_repository.dart';
import '../localization/app_localizations.dart';
import '../widgets/dialog_kit.dart';

class ManageCollaboratorsScreen extends StatelessWidget {
  const ManageCollaboratorsScreen({super.key});

  static const _knownRoles = ['full', 'dynamic', 'read'];
  static const _emerald = Color(0xFF059669);
  static const _rose = Color(0xFFE11D48);

  @override
  Widget build(BuildContext context) {
    final currentUser = sl<AuthRepository>().currentUser;
    final collaboratorRepository = sl<CollaboratorRepository>();
    final ownerEmail = currentUser?.email;
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [Color(0xFF12171A), Color(0xFF0F1211)]
          : const [Color(0xFFEAFBF3), Color(0xFFF7FBF9)],
    );

    void showError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.manageCollaborators,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: ownerEmail == null
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
                      child: Text(
                        t.noCollaborators,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    itemCount: collaborators.length,
                    itemBuilder: (context, index) {
                      final collaborator = collaborators[index];
                      final email = collaborator.email;
                      final currentRole = collaborator.role;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        elevation: 0,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.62),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                              14, 6, 4, 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _emerald.withValues(alpha: 0.10),
                              border: Border.all(
                                color: _emerald.withValues(alpha: 0.35),
                                width: 1.6,
                              ),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 22,
                              color: isDark
                                  ? Colors.grey.shade200
                                  : const Color(0xFF065F46),
                            ),
                          ),
                          title: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: -0.1,
                              color: isDark
                                  ? Colors.grey.shade100
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${t.permissionPrefix} ${_getRoleDescription(t, currentRole)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<String>(
                                value: _knownRoles.contains(currentRole)
                                    ? currentRole
                                    : null,
                                hint: _knownRoles.contains(currentRole)
                                    ? null
                                    : Text(
                                        t.roleUnknown,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                underline: const SizedBox.shrink(),
                                borderRadius: BorderRadius.circular(14),
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
                                  if (newRole == null ||
                                      newRole == currentRole) {
                                    return;
                                  }
                                  try {
                                    await collaboratorRepository.updateRole(
                                      docId: collaborator.docId,
                                      ownerEmail: ownerEmail,
                                      collaboratorEmail: email,
                                      role: newRole,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text(t.savedSuccessfully)),
                                      );
                                    }
                                  } on Failure catch (failure) {
                                    if (context.mounted) {
                                      showError(failure.message);
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: _rose),
                                tooltip: t.delete,
                                onPressed: () => _confirmRemove(
                                  context,
                                  collaboratorRepository,
                                  collaborator,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    CollaboratorRepository repository,
    Collaborator collaborator,
  ) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => DialogKit.frame(
        ctx,
        title: Text(t.delete),
        content: Text(t.removeCollaboratorConfirm(collaborator.email)),
        actions: [
          DialogKit.cancelButton(ctx, t.cancel),
          DialogKit.saveButton(
            ctx,
            t.delete,
            DialogAccents.rose,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await repository.removeCollaborator(
        docId: collaborator.docId,
        collaboratorEmail: collaborator.email,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.collaboratorRemoved)),
        );
      }
    } on Failure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      }
    }
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
