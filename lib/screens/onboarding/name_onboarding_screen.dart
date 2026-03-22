import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import 'system_boot_screen.dart';
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
  late final Future<PackageInfo> _packageInfo;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

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
      FocusManager.instance.primaryFocus?.unfocus();

      final theme = Theme.of(context);
      // 1) Delay navigation by exactly 1 frame so the button can visibly enter
      // loading state and the keyboard can dismiss cleanly.
      await SchedulerBinding.instance.endOfFrame;

      // 2) Pre-warm the boot screen (paints/text layout) before navigation so
      // the first frame is less likely to hitch.
      SystemBootScreen.prewarm(theme);

      if (!mounted) return;
      await Navigator.of(context).push(_bootRoute(identityName: name));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Route<void> _bootRoute({required String identityName}) {
    return PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SystemBootScreen(identityName: identityName);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(opacity: fade, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignSystem.spacing16,
              DesignSystem.spacing12,
              DesignSystem.spacing16,
              DesignSystem.spacing16,
            ),
            child: Column(
              children: [
                // Top header row (SYSTEM_INIT | BUILD_...)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 18,
                        color: AppColors.neonBlue.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: DesignSystem.spacing8),
                      Text(
                        'SYSTEM_INIT',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.neonBlue.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                            ),
                      ),
                      const Spacer(),
                      FutureBuilder<PackageInfo>(
                        future: _packageInfo,
                        builder: (context, snap) {
                          final info = snap.data;
                          final build = info?.buildNumber.trim() ?? '';
                          final version = info?.version.trim() ?? '';
                          final label = (version.isEmpty)
                              ? 'BUILD_—'
                              : (build.isEmpty)
                                  ? 'BUILD_v$version'
                                  : 'BUILD_v$version.$build';
                          return Text(
                            label,
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color:
                                          AppColors.textSecondary.withValues(alpha: 0.7),
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DesignSystem.spacing24),

                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'IDENTIFICATION_REQUIRED',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.neonBlue.withValues(alpha: 0.75),
                                  letterSpacing: 2.6,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: DesignSystem.spacing24),
                          Text(
                            'IDENTIFY\nYOURSELF',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  height: 0.95,
                                  letterSpacing: 1.8,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DesignSystem.spacing12),
                          Center(
                            child: Container(
                              height: 4,
                              width: 84,
                              decoration: BoxDecoration(
                                color: AppColors.neonBlue.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: DesignSystem.spacing24),
                          IgrisInputField(
                            label: null,
                            hint: 'ENTER DESIGNATION...',
                            controller: _nameCtrl,
                            errorText: _error,
                            autofocus: true,
                            prefixIcon: Icons.person_outline,
                            onChanged: (_) {
                              if (_error != null) setState(() => _error = null);
                            },
                          ),
                          const SizedBox(height: DesignSystem.spacing12),
                          Text(
                            'AWAITING INPUT FOR SYSTEM\nSYNCHRONIZATION',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color:
                                      AppColors.textSecondary.withValues(alpha: 0.55),
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: IgrisButton(
                    text: 'INITIALIZE',
                    variant: IgrisButtonVariant.primary,
                    icon: Icons.arrow_forward,
                    fullWidth: true,
                    isLoading: _saving,
                    onPressed: _saving ? null : _continue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
