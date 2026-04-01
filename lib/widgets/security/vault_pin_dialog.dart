import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/fuel_vault_provider.dart';

/// Prompts the user for the existing Fuel Vault 4-digit PIN.
///
/// Returns `true` when the PIN was verified; otherwise `false`.
Future<bool> showVaultPinDialog({
  required BuildContext context,
  required WidgetRef ref,
  String title = 'Enter Vault PIN',
  String subtitle = 'Enter your 4-digit PIN',
  bool shareSessionUnlock = true,
  bool barrierDismissible = true,
}) async {
  final isPinSet = ref.read(fuelVaultProvider).isPinSet;
  if (!isPinSet) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text(
          'Vault PIN not set',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Set a Fuel Vault PIN first to protect this section.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
    return false;
  }

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => _VaultPinDialog(title: title, subtitle: subtitle),
  );

  if (ok == true) {
    if (shareSessionUnlock) {
      // Share session unlock with Fuel Vault.
      ref.read(fuelVaultProvider.notifier).unlock();
    }
    return true;
  }
  return false;
}

class _VaultPinDialog extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;

  const _VaultPinDialog({required this.title, required this.subtitle});

  @override
  ConsumerState<_VaultPinDialog> createState() => _VaultPinDialogState();
}

class _VaultPinDialogState extends ConsumerState<_VaultPinDialog> {
  String _entered = '';
  String? _errorText;

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _errorText = null;
    });
    if (_entered.length == 4) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _errorText = null;
    });
  }

  void _verify() {
    final ok = ref.read(fuelVaultProvider.notifier).verifyPin(_entered);
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _entered = '';
      _errorText = 'Incorrect PIN.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.neonBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.neonBlue : Colors.transparent,
                    border: Border.all(
                      color: filled ? AppColors.neonBlue : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            // Error text
            SizedBox(
              height: 26,
              child: _errorText == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 6),

            _NumPad(onDigit: _onDigit, onBackspace: _onBackspace),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _NumPad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    Widget digitButton(String digit) {
      return SizedBox(
        width: 64,
        height: 56,
        child: TextButton(
          onPressed: () => onDigit(digit),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.backgroundElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in digits) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map(digitButton).toList(),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 64, height: 56),
              digitButton('0'),
              SizedBox(
                width: 64,
                height: 56,
                child: IconButton(
                  onPressed: onBackspace,
                  icon: const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.backgroundElevated,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
