import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../providers/progression_provider.dart';
import '../../widgets/hunter_radar_chart.dart';

class StatsAllocationScreen extends ConsumerStatefulWidget {
  const StatsAllocationScreen({super.key});

  @override
  ConsumerState<StatsAllocationScreen> createState() =>
      _StatsAllocationScreenState();
}

class _StatsAllocationScreenState extends ConsumerState<StatsAllocationScreen> {
  late Map<String, int> _stats;
  late int _unspent;

  bool _initialized = false;

  static const int _maxValue = 99;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final profile = ref.read(progressionProvider);
    _stats = {
      ...profile.stats,
    };
    for (final k in kHunterStatKeys) {
      _stats[k] = (_stats[k] ?? 0).clamp(0, _maxValue);
    }

    _unspent = profile.unspentStatPoints;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(progressionProvider);

    // If points changed (earned from XP) while screen is open, keep UI stable.
    // The user can re-open to refresh.

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '♦  STAT  ALLOCATION',
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.neonBlue.withValues(alpha: 0.2),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: DesignSystem.paddingAll16,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: DesignSystem.paddingAll16,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSurface,
                  borderRadius: DesignSystem.radiusStandard,
                  border: Border.all(
                    color: AppColors.dividerColor,
                    width: DesignSystem.borderThin,
                  ),
                ),
                child: Row(
                  children: [
                    HunterRadarChart(
                      stats: _stats,
                      size: 140,
                      maxValue: _maxValue,
                    ),
                    SizedBox(width: DesignSystem.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AVAILABLE POINTS',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: DesignSystem.spacing8),
                          Text(
                            '$_unspent',
                            style: TextStyle(
                              color: _unspent > 0
                                  ? AppColors.royalGold
                                  : AppColors.textSecondary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: DesignSystem.spacing12),
                          Text(
                            'Level: ${profile.level}  •  Rank: ${profile.rank}',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignSystem.spacing16),
              Expanded(
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  itemCount: kHunterStatKeys.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DesignSystem.spacing12),
                  itemBuilder: (context, index) {
                    final key = kHunterStatKeys[index];
                    final value = (_stats[key] ?? 0).clamp(0, _maxValue);
                    final canInc = _unspent > 0 && value < _maxValue;
                    final canDec = value > 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacing16,
                        vertical: DesignSystem.spacing12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSurface,
                        borderRadius: DesignSystem.radiusStandard,
                        border: Border.all(
                          color: AppColors.dividerColor,
                          width: DesignSystem.borderThin,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              hunterStatLabel(key),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            value.toString(),
                            style: TextStyle(
                              color: AppColors.neonBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StepButton(
                            icon: Icons.remove,
                            enabled: canDec,
                            onTap: () {
                              if (!canDec) return;
                              setState(() {
                                _stats[key] = (value - 1).clamp(0, _maxValue);
                                _unspent += 1;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _StepButton(
                            icon: Icons.add,
                            enabled: canInc,
                            onTap: () {
                              if (!canInc) return;
                              setState(() {
                                _stats[key] = (value + 1).clamp(0, _maxValue);
                                _unspent -= 1;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonBlue,
                    foregroundColor: AppColors.backgroundPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignSystem.spacing16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignSystem.radiusStandard,
                    ),
                  ),
                  onPressed: () async {
                    await ref.read(progressionProvider.notifier).updateStats(
                          stats: _stats,
                          unspentStatPoints: _unspent,
                        );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.neonBlue.withValues(alpha: 0.95)
        : AppColors.textMuted.withValues(alpha: 0.5);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: DesignSystem.spacing32,
        height: DesignSystem.spacing32,
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: enabled
                ? AppColors.neonBlue.withValues(alpha: 0.35)
                : AppColors.dividerColor,
          ),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
