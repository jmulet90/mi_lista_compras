import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../domain/entities/premium_status.dart';
import '../../domain/repositories/premium_repository.dart';
import '../../domain/usecases/check_premium.dart';
import '../../domain/usecases/purchase_premium.dart';
import '../../domain/usecases/restore_premium.dart';
import '../localization/app_localizations.dart';

/// Diálogo de compra del desbloqueo premium (compra única).
///
/// [reason] muestra un mensaje contextual opcional explicando qué
/// función quedó bloqueada.
Future<void> showPaywall(BuildContext context, {String? reason}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _PaywallDialog(reason: reason),
  );
}

class _PaywallDialog extends StatefulWidget {
  const _PaywallDialog({this.reason});

  final String? reason;

  @override
  State<_PaywallDialog> createState() => _PaywallDialogState();
}

class _PaywallDialogState extends State<_PaywallDialog> {
  bool _buying = false;

  Future<void> _buy() async {
    setState(() => _buying = true);
    final t = AppLocalizations.of(context);
    final success = await sl<PurchasePremiumUseCase>()();
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

        final price = status.priceText ?? t.premiumPriceFallback;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium,
                  color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Expanded(child: Text(t.premiumTitle)),
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
              _benefitRow(Icons.category_outlined,
                  t.premiumBenefit1, status.isPremium),
              const SizedBox(height: 10),
              _benefitRow(Icons.shopping_basket_outlined,
                  t.premiumBenefit2, status.isPremium),
              const SizedBox(height: 10),
              _benefitRow(Icons.group_outlined,
                  t.premiumBenefitCollaborators, status.isPremium),
              const SizedBox(height: 10),
              _benefitRow(Icons.dark_mode_outlined,
                  t.premiumBenefitDarkMode, status.isPremium),
              const SizedBox(height: 10),
              _benefitRow(Icons.grid_view_outlined,
                  t.premiumBenefitGalleryView, status.isPremium),
              const SizedBox(height: 10),
              _benefitRow(Icons.favorite_outline,
                  t.premiumBenefit3, status.isPremium),
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
            if (!status.isPremium)
              TextButton(
                onPressed:
                    _buying ? null : () => sl<RestorePurchasesUseCase>()(),
                child: Text(t.premiumRestore),
              ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: (_buying || status.isPremium) ? null : _buy,
              icon: _buying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_open, size: 18),
              label: Text(status.isPremium
                  ? t.premiumActive
                  : t.unlockFor(price)),
            ),
          ],
        );
      },
    );
  }

  Widget _benefitRow(IconData icon, String text, bool premium) {
    return Row(
      children: [
        Icon(
          premium ? Icons.check_circle : icon,
          size: 20,
          color: premium ? const Color(0xFFC27A22) : Colors.amber.shade700,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
