import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../data/bootstrap/app_initializer.dart';
import '../../domain/repositories/collaborator_repository.dart';
import '../../domain/repositories/premium_repository.dart';
import '../app_settings.dart';
import '../localization/app_localizations.dart';
import '../screens/manage_collaborators_screen.dart';
import 'paywall_dialog.dart';
import 'premium_limits.dart';

/// Paleta compartida con las pantallas principales.
class DrawerAccents {
  static const emerald = Color(0xFF059669);
  static const rose = Color(0xFFE11D48);
  static const amber = Color(0xFFD97706);
  static const ink = Color(0xFF0F172A);
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isOwner = true;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    try {
      final access = await sl<CollaboratorRepository>().resolveMyAccess();
      if (mounted) {
        setState(() {
          _isOwner = access == null || access.isOwner;
        });
      }
    } catch (_) {
      // Default to showing everything on error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = AppSettings.of(context);
    final notifier = AppSettings.notifierOf(context);
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.grey.shade100 : DrawerAccents.ink;
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF12171A), Color(0xFF0F1211)]
                : const [Color(0xFFEAFBF3), Color(0xFFF7FBF9)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Encabezado: ícono de app + nombre + correo.
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 22),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: DrawerAccents.emerald,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.appName,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? t.notAuthenticated,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: subColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Sección: preferencias.
              _GlassSection(
                isDark: isDark,
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: _iconChip(Icons.language, DrawerAccents.emerald),
                    title: Text(t.language, style: _titleStyle(titleColor)),
                    subtitle: Text(
                      '${t.currentLanguage.flag} ${t.currentLanguage.nativeName}',
                      style: TextStyle(color: subColor, fontSize: 12.5),
                    ),
                    trailing: Icon(Icons.arrow_drop_down, color: subColor),
                    onTap: () =>
                        _openLanguageSheet(context, settings, notifier),
                  ),
                  SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    secondary:
                        _iconChip(Icons.dark_mode_outlined, DrawerAccents.emerald),
                    title: Text(t.darkMode, style: _titleStyle(titleColor)),
                    value: settings.themeMode == ThemeMode.dark,
                    activeThumbColor: DrawerAccents.emerald,
                    onChanged: (value) async {
                      if (!PremiumLimits.checkCanEdit(context)) return;
                      if (value &&
                          !await PremiumLimits.canUseAppearanceFeature(
                              context)) {
                        return;
                      }
                      notifier.value = notifier.value.copyWith(
                        themeMode:
                            value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sección: colaboradores (solo el owner).
              if (_isOwner)
                _GlassSection(
                  isDark: isDark,
                  children: [
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: _iconChip(
                          Icons.person_add_alt_outlined, DrawerAccents.emerald),
                      title:
                          Text(t.addCollaborator, style: _titleStyle(titleColor)),
                      onTap: () async {
                        if (!await PremiumLimits.canManageCollaborators(context)) {
                          return;
                        }
                        if (!context.mounted) return;
                        await _sendInvitation(context);
                      },
                    ),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: _iconChip(
                          Icons.manage_accounts_outlined, DrawerAccents.emerald),
                      title: Text(t.managePermissions,
                          style: _titleStyle(titleColor)),
                      subtitle: Text(
                        t.managePermissionsSub,
                        style: TextStyle(color: subColor, fontSize: 12.5),
                      ),
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
                  ],
                ),
              if (_isOwner) const SizedBox(height: 12),

              // Sección: premium.
              _GlassSection(
                isDark: isDark,
                children: [_PremiumTile(isDark: isDark)],
              ),
              const SizedBox(height: 12),

              // Sección: acerca de.
              _GlassSection(
                isDark: isDark,
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: _iconChip(Icons.info_outline, DrawerAccents.emerald),
                    title: Text(t.about, style: _titleStyle(titleColor)),
                    subtitle: Text(
                      '${t.appName} · ${t.version}',
                      style: TextStyle(color: subColor, fontSize: 12.5),
                    ),
                  ),
                ],
              ),

              // Cerrar sesión, fuera de las tarjetas.
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  leading: _iconChip(Icons.logout, DrawerAccents.rose),
                  title: Text(
                    t.signOut,
                    style: TextStyle(
                      color: DrawerAccents.rose,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                    // Limpiar la sesión local guardada para que la pantalla
                    // muestre el login (nunca debe quedar presa).
                    await sl<AppInitializer>().setLastAuthUid(null);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _titleStyle(Color color) => TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: -0.1,
        color: color,
      );

  /// Ícono dentro de un chip redondeado con tinte del acento.
  Widget _iconChip(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 21, color: color),
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
          backgroundColor: DrawerAccents.emerald,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.errorSaving),
          backgroundColor: DrawerAccents.rose,
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
                            ? const Icon(Icons.check_circle,
                                color: DrawerAccents.emerald)
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

/// Tarjeta translúcida que agrupa opciones, igual al estilo de la
/// pantalla principal.
class _GlassSection extends StatelessWidget {
  const _GlassSection({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.62),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.8),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _PremiumTile extends StatefulWidget {
  const _PremiumTile({required this.isDark});

  final bool isDark;

  @override
  State<_PremiumTile> createState() => _PremiumTileState();
}

class _PremiumTileState extends State<_PremiumTile> {
  bool _effectivePremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final effective = await PremiumLimits.isPremiumEffective();
    if (mounted) setState(() => _effectivePremium = effective);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = widget.isDark;

    if (_effectivePremium) {
      return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: _chip(),
        title: Text(
          t.premiumTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDark ? Colors.grey.shade100 : DrawerAccents.ink,
          ),
        ),
        trailing: const Icon(Icons.check_circle,
            color: DrawerAccents.emerald),
      );
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: _chip(),
      title: Text(
        t.premiumTitle,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDark ? Colors.grey.shade100 : DrawerAccents.ink,
        ),
      ),
      subtitle: Text(
        sl<PremiumRepository>().current().priceText ?? t.premiumPriceFallback,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 12.5,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showPaywall(context),
      onLongPress: kDebugMode
          ? () => sl<PremiumRepository>().toggleDebugOverride()
          : null,
    );
  }

  Widget _chip() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: DrawerAccents.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.workspace_premium,
        size: 21,
        color: DrawerAccents.amber,
      ),
    );
  }
}
