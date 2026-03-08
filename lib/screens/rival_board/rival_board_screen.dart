import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../models/rival.dart';
import '../../providers/rival_provider.dart';
import '../../widgets/layout/igris_screen_scaffold.dart';
import '../../widgets/ui/igris_card.dart';
import 'add_rival_bottom_sheet.dart';
import 'rival_detail_screen.dart';

/// Main Rival Board screen — strategic intelligence dashboard.
///
/// Shows all rivals as scrollable cards sorted by last-updated date.
/// FAB opens the Add Rival sheet.
class RivalBoardScreen extends ConsumerWidget {
  const RivalBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rivalProvider);

    return IgrisScreenScaffold(
      title: 'Rival Board',
      applyPadding: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        backgroundColor: AppColors.backgroundElevated,
        foregroundColor: AppColors.neonBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: DesignSystem.radiusStandard,
          side: BorderSide(
            color: AppColors.neonBlue.withValues(alpha: 0.6),
            width: DesignSystem.borderThin,
          ),
        ),
        label: const Text(
          'Add Rival',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        icon: const Icon(Icons.add, size: 20),
      ),
      child: state.rivals.isEmpty
          ? _buildEmpty(context)
          : ListView.builder(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                DesignSystem.spacing16,
                DesignSystem.spacing16,
                DesignSystem.spacing16,
                DesignSystem.spacing16 + 72, // clear FAB
              ),
              itemCount: state.rivals.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: DesignSystem.spacing12),
                child: _RivalCard(rival: state.rivals[index]),
              ),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: DesignSystem.paddingAll32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radar,
              size: DesignSystem.iconHero,
              color: AppColors.textMuted,
            ),
            SizedBox(height: DesignSystem.spacing16),
            Text(
              'No rivals tracked',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: DesignSystem.spacing8),
            Text(
              'Add people who push you to be better.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AddRivalBottomSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// Rival Card
// ---------------------------------------------------------------------------

class _RivalCard extends StatelessWidget {
  final Rival rival;

  const _RivalCard({required this.rival});

  Color get _threatColor {
    final t = rival.threatLevel ?? 0;
    if (t <= 2) return AppColors.deepBlue;
    if (t == 3) return AppColors.royalGold;
    return AppColors.bloodRed;
  }

  @override
  Widget build(BuildContext context) {
    final hasThreatlevel = rival.threatLevel != null;
    final updated = DateFormat('MMM d').format(rival.lastUpdated);

    return IgrisCard(
      variant: IgrisCardVariant.elevated,
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RivalDetailScreen(rival: rival),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: threat indicator stripe (if set) ──────────────────
          if (hasThreatlevel)
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _threatColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DesignSystem.radius16),
                  topRight: Radius.circular(DesignSystem.radius16),
                ),
              ),
            ),

          Padding(
            padding: DesignSystem.paddingAll16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Domain row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rival.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    SizedBox(width: DesignSystem.spacing8),
                    _DomainChip(label: rival.domain),
                  ],
                ),

                // Threat bars (compact, inline)
                if (hasThreatlevel) ...[
                  SizedBox(height: DesignSystem.spacing8),
                  _ThreatBars(level: rival.threatLevel!),
                ],

                // Achievement
                if (rival.lastAchievement.trim().isNotEmpty) ...[
                  SizedBox(height: DesignSystem.spacing12),
                  Text(
                    rival.lastAchievement,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                ],

                // Updated at
                SizedBox(height: DesignSystem.spacing12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: DesignSystem.iconSmall,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: DesignSystem.spacing4),
                    Text(
                      'Updated $updated',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: DesignSystem.iconMedium,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tiny chip / indicator sub-widgets
// ---------------------------------------------------------------------------

class _DomainChip extends StatelessWidget {
  final String label;

  const _DomainChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignSystem.spacing8,
        vertical: DesignSystem.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.neonBlue.withValues(alpha: 0.10),
        borderRadius: DesignSystem.radiusSmall,
        border: Border.all(
          color: AppColors.neonBlue.withValues(alpha: 0.3),
          width: DesignSystem.borderThin,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.neonBlue,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}

/// 5 compact bars - filled = active threat levels.
class _ThreatBars extends StatelessWidget {
  final int level;

  const _ThreatBars({required this.level});

  Color _color(int bar) {
    if (bar <= 2) return AppColors.deepBlue;
    if (bar == 3) return AppColors.royalGold;
    return AppColors.bloodRed;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final bar = i + 1;
        final active = bar <= level;
        return Padding(
          padding: EdgeInsets.only(right: DesignSystem.spacing4),
          child: Container(
            width: 16,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? _color(bar)
                  : AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: active
                    ? _color(bar)
                    : AppColors.textMuted.withValues(alpha: 0.25),
                width: DesignSystem.borderThin,
              ),
            ),
          ),
        );
      }),
    );
  }
}
