import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/fuel_vault_provider.dart';
import 'fuel_vault_screen.dart';

enum _AuthMode { setupPin, confirmPin, enterPin }

class VaultAuthScreen extends ConsumerStatefulWidget {
  const VaultAuthScreen({super.key});

  @override
  ConsumerState<VaultAuthScreen> createState() => _VaultAuthScreenState();
}

class _VaultAuthScreenState extends ConsumerState<VaultAuthScreen> {
  late _AuthMode _mode;
  String _entered = '';
  String _firstPin = '';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final isPinSet = ref.read(fuelVaultProvider).isPinSet;
    _mode = isPinSet ? _AuthMode.enterPin : _AuthMode.setupPin;
  }

  String get _title => switch (_mode) {
        _AuthMode.setupPin => 'Create Vault PIN',
        _AuthMode.confirmPin => 'Confirm PIN',
        _AuthMode.enterPin => 'Enter Vault PIN',
      };

  String get _subtitle => switch (_mode) {
        _AuthMode.setupPin => 'Set a 4-digit PIN to protect your vault',
        _AuthMode.confirmPin => 'Re-enter to confirm',
        _AuthMode.enterPin => 'Enter your 4-digit PIN',
      };

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _errorText = null;
    });
    if (_entered.length == 4) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _errorText = null;
    });
  }

  void _handleComplete() {
    switch (_mode) {
      case _AuthMode.setupPin:
        setState(() {
          _firstPin = _entered;
          _entered = '';
          _mode = _AuthMode.confirmPin;
        });

      case _AuthMode.confirmPin:
        if (_entered == _firstPin) {
          ref.read(fuelVaultProvider.notifier).setPin(_entered).then((_) {
            ref.read(fuelVaultProvider.notifier).unlock();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const FuelVaultScreen()),
            );
          });
        } else {
          setState(() {
            _entered = '';
            _firstPin = '';
            _mode = _AuthMode.setupPin;
            _errorText = 'PINs did not match. Try again.';
          });
        }

      case _AuthMode.enterPin:
        final ok = ref.read(fuelVaultProvider.notifier).verifyPin(_entered);
        if (ok) {
          ref.read(fuelVaultProvider.notifier).unlock();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FuelVaultScreen()),
          );
        } else {
          setState(() {
            _entered = '';
            _errorText = 'Incorrect PIN.';
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Lock icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppColors.neonBlue,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              _title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              _subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
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
              height: 28,
              child: _errorText != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : null,
            ),

            const Spacer(),

            // Numpad
            _NumPad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
            ),

            const SizedBox(height: 32),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          for (final row in digits)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((d) => _DigitButton(digit: d, onTap: onDigit)).toList(),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Blank placeholder
              const SizedBox(width: 72, height: 72),
              _DigitButton(digit: '0', onTap: onDigit),
              SizedBox(
                width: 72,
                height: 72,
                child: IconButton(
                  onPressed: onBackspace,
                  icon: const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
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

class _DigitButton extends StatelessWidget {
  final String digit;
  final void Function(String) onTap;

  const _DigitButton({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: () => onTap(digit),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          shape: const CircleBorder(),
          backgroundColor: AppColors.backgroundElevated,
        ),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
