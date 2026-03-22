import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../providers/progression_provider.dart';
import '../../widgets/layout/igris_screen_scaffold.dart';
import '../../widgets/ui/igris_button.dart';
import '../../widgets/ui/igris_input_field.dart';

class NameOnboardingScreen extends ConsumerStatefulWidget {
  const NameOnboardingScreen({super.key});

  @override
  ConsumerState<NameOnboardingScreen> createState() =>
      _NameOnboardingScreenState();
}

class _NameOnboardingScreenState extends ConsumerState<NameOnboardingScreen> {
  final _nameCtrl = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      await ref.read(progressionProvider.notifier).updateName(name);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: IgrisScreenScaffold(
        title: 'Welcome',
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "What's your name?",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DesignSystem.spacing8),
                Text(
                  'This will be shown on your profile.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DesignSystem.spacing24),
                IgrisInputField(
                  label: 'Name *',
                  hint: 'Enter your name',
                  controller: _nameCtrl,
                  errorText: _error,
                  autofocus: true,
                  prefixIcon: Icons.person_outline,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                SizedBox(height: DesignSystem.spacing16),
                IgrisButton(
                  text: 'Continue',
                  variant: IgrisButtonVariant.primary,
                  icon: Icons.arrow_forward,
                  fullWidth: true,
                  isLoading: _saving,
                  onPressed: _saving ? null : _continue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
