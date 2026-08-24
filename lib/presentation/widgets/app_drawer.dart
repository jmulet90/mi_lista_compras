import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../domain/entities/premium_status.dart';
import '../../domain/repositories/collaborator_repository.dart';
import '../../domain/repositories/premium_repository.dart';
import '../../domain/usecases/check_premium.dart';
import '../app_settings.dart';
import '../localization/app_localizations.dart';
import '../screens/manage_collaborators_screen.dart';
import 'paywall_dialog.dart';
import 'premium_limits.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = AppSettings.of(context);
    final notifier = AppSettings.notifierOf(context);
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    t.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? t.notAuthenticated,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // 1. Idioma
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(t.language),
              subtitle: Text(
                '${t.currentLanguage.flag} ${t.currentLanguage.nativeName}',
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () =>
                  _openLanguageSheet(context, settings, notifier),
            ),

            // 2. Modo oscuro (premium)
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text(t.darkMode),
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (value) async {
                if (value &&
                    !await PremiumLimits.canUseAppearanceFeature(context)) {
                  return;
                }
                notifier.value = notifier.value.copyWith(
                  themeMode:
                      value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),

            const Divider(),

            // 3. Enviar invitación (premium)
            ListTile(
              leading: const Icon(Icons.person_add_alt_outlined),
              title: Text(t.addCollaborator),
              onTap: () async {
                if (!await PremiumLimits.canManageCollaborators(context)) {
                  return;
                }
                if (!context.mounted) return;
                await _sendInvitation(context);
              },
            ),

            // 4. Gestionar permisos (premium)
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: Text(t.managePermissions),
              subtitle: Text(t.managePermissionsSub),
              onTap: () async {
                if (!await PremiumLimits.canManageCollaborators(context)) {
                  return;
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageCollaboratorsScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            // 5. Hazte Premium
            const _PremiumTile(),

            const Divider(),

            // 6. Acerca de la app
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(t.about),
              subtitle: Text('${t.appName} · ${t.version}'),
            ),

            // 7. Cerrar sesión
            ListTile(
              leading:
                  Icon(Icons.logout, color: Colors.red.shade700),
              title: Text(
                t.signOut,
                style: TextStyle(color: Colors.red.shade700),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvitation(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.addCollaborator),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.collaboratorPrompt,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t.emailLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(t.add),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !context.mounted) return;

    try {
      final ownerEmail =
          FirebaseAuth.instance.currentUser?.email ?? '';
      await sl<CollaboratorRepository>().inviteCollaborator(
        ownerEmail: ownerEmail,
        collaboratorEmail: email,
        role: 'read',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.savedSuccessfully),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.errorSaving),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _openLanguageSheet(
    BuildContext context,
    AppSettingsData settings,
    ValueNotifier<AppSettingsData> notifier,
  ) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final current = t.currentLanguage;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(current.flag,
                        style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(current.nativeName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      t.selectLanguage,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final lang
                        in AppLocalizations.supportedLanguages)
                      ListTile(
                        leading: Text(lang.flag,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(lang.nativeName),
                        trailing: lang.code == current.code
                            ? Icon(Icons.check_circle,
                                color: Colors.green.shade600)
                            : null,
                        onTap: () {
                          notifier.value = notifier.value.copyWith(
                              language: lang.code);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _PremiumTile extends StatelessWidget {
  const _PremiumTile();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return StreamBuilder<PremiumStatus>(
      stream: sl<CheckPremiumUseCase>()(),
      builder: (context, snapshot) {
        final status =
            snapshot.data ?? sl<PremiumRepository>().current();
        debugPrint(
          '[INFO] PremiumTile: isPremium=${status.isPremium} '
          '(snapshot tiene datos: ${snapshot.hasData})',
        );

        if (status.isPremium) {
          return ListTile(
            leading:
                Icon(Icons.workspace_premium, color: Colors.amber.shade700),
            title: Text(t.premiumTitle),
            trailing:
                Icon(Icons.check_circle, color: Colors.green.shade600),
          );
        }

        return ListTile(
          leading:
              Icon(Icons.workspace_premium, color: Colors.amber.shade700),
          title: Text(t.premiumTitle),
          subtitle: Text(status.priceText ?? t.premiumPriceFallback),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showPaywall(context),
          onLongPress: kDebugMode
              ? () => sl<PremiumRepository>().toggleDebugOverride()
              : null,
        );
      },
    );
  }
}
