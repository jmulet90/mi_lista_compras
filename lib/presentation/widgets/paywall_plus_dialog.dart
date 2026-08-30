import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../domain/entities/premium_status.dart';
import '../../domain/repositories/premium_repository.dart';
import '../../domain/usecases/check_premium.dart';
import '../../domain/usecases/purchase_plus.dart';
import '../../domain/usecases/restore_premium.dart';
import '../localization/app_localizations.dart';

/// Diálogo de compra del plan Premium Plus (suscripción mensual).
///
/// [reason] muestra un mensaje contextual opcional explicando qué
/// función quedó bloqueada.
Future<void> showPremiumPlusPaywall(BuildContext context, {String? reason}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _PremiumPlusPaywallDialog(reason: reason),
  );
}

class _PremiumPlusPaywallDialog extends StatefulWidget {
  const _PremiumPlusPaywallDialog({this.reason});

  final String? reason;

  @override
  State<_PremiumPlusPaywallDialog> createState() =>
      _PremiumPlusPaywallDialogState();
}

class _PremiumPlusPaywallDialogState extends State<_PremiumPlusPaywallDialog> {
  bool _buying = false;

  Future<void> _buy() async {
    setState(() => _buying = true);
    final t = AppLocalizations.of(context);
    final success = await sl<PurchasePremiumPlusUseCase>()();
    if (!mounted) return;
    setState(() => _buying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? t.purchaseSuccess : t.purchaseError),
        backgroundColor:
            success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return StreamBuilder<PremiumStatus>(
      stream: sl<CheckPremiumUseCase>()(),
      builder: (context, snapshot) {
        final status =
            snapshot.data ?? sl<PremiumRepository>().current();

        final price = status.priceTextPlus ?? t.plusPriceFallback;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF184878)),
              const SizedBox(width: 8),
              Expanded(child: Text(t.plusTitle)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.reason != null) ...[
                Text(
                  widget.reason!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ],
              _benefitRow(
                  Icons.ios_share_outlined, t.plusBenefitExport, status),
              const SizedBox(height: 10),
              _benefitRow(
                  Icons.drive_file_move_outline, t.plusBenefitSubcategories,
                  status),
              const SizedBox(height: 10),
              _benefitRow(
                  Icons.notifications_active_outlined, t.plusBenefitNotifications,
                  status),
              const SizedBox(height: 10),
              _benefitRow(
                  Icons.auto_awesome_outlined, t.plusBenefitSuggestions,
                  status),
              const SizedBox(height: 10),
              _benefitRow(
                  Icons.group_add_outlined, t.plusBenefitCollaborators, status),
              if (status.pending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.purchasePending,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            if (!status.isPremiumPlus)
              TextButton(
                onPressed:
                    _buying ? null : () => sl<RestorePurchasesUseCase>()(),
                child: Text(t.premiumRestore),
              ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF184878),
                foregroundColor: Colors.white,
              ),
              onPressed: (_buying || status.isPremiumPlus) ? null : _buy,
              icon: _buying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_open, size: 18),
              label: Text(status.isPremiumPlus
                  ? t.plusActive
                  : t.unlockPlusFor(price)),
            ),
          ],
        );
      },
    );
  }

  Widget _benefitRow(IconData icon, String text, PremiumStatus status) {
    return Row(
      children: [
        Icon(
          status.isPremiumPlus ? Icons.check_circle : icon,
          size: 20,
          color: status.isPremiumPlus
              ? const Color(0xFFC27A22)
              : const Color(0xFF184878),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}