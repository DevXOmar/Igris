import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../providers/grace_provider.dart';
import '../../providers/domain_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/ui/igris_ui.dart';
import '../../widgets/layout/igris_screen_scaffold.dart';
import '../../services/backup_service.dart';

/// Settings screen for app configuration and grace token management
/// Refactored with Igris UI components for consistent styling
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _backupService = BackupService();
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        final build = info.buildNumber.trim();
        _appVersion = build.isEmpty ? info.version : '${info.version}+$build';
      });
    } catch (_) {
    }
  }

  Future<void> _runBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final path = await _backupService.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved to:\n$path'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _runRestore() async {
    setState(() => _isRestoring = true);
    try {
      final preview = await _backupService.pickBackupPreview();
      if (!mounted) return;
      if (preview == null) return;

      final summary = StringBuffer()
        ..writeln('Backup details')
        ..writeln('• Timestamp (UTC): ${preview.timestampUtc}')
        ..writeln('• Device: ${preview.device}')
        ..writeln('• App version: ${preview.appVersion}')
        ..writeln('')
        ..writeln('Contains')
        ..writeln('• Domains: ${preview.domainsCount}')
        ..writeln('• Tasks: ${preview.tasksCount}')
        ..writeln('• Daily logs: ${preview.dailyLogsCount}')
        ..writeln('• Rivals: ${preview.rivalsCount}')
        ..writeln('• Fuel Vault entries: ${preview.fuelVaultCount}')
        ..writeln('')
        ..writeln('Profile')
        ..writeln('• Level: ${preview.profileLevel}')
        ..writeln('• Rank: ${preview.profileRank}')
        ..writeln('• Name: ${preview.profileName.isEmpty ? "(not set)" : preview.profileName}')
        ..writeln('')
        ..writeln('This will REPLACE all current data with the backup.')
        ..writeln('This action cannot be undone.');

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundElevated,
          title: const Text(
            'Restore Backup?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            summary.toString(),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Restore',
                style: TextStyle(color: AppColors.neonBlue),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await _backupService.restoreFromEnvelope(preview.envelope);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore complete. Please restart the app to see your data.'),
          duration: Duration(seconds: 6),
        ),
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final graceState = ref.watch(graceProvider);
    final domainState = ref.watch(domainProvider);
    final taskState = ref.watch(taskProvider);
    
    final daysUntilReset = ref.read(graceProvider.notifier).getDaysUntilReset();

    return IgrisScreenScaffold(
      title: 'Settings',
      applyPadding: false,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: DesignSystem.paddingAll16,
        children: [
          // Grace System Section
          IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Padding(
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: DesignSystem.spacing8),
                      Text(
                        'Grace System',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  _buildInfoRow(
                    context,
                    'Weekly Grace Tokens',
                    '${graceState.weeklyGraceLeft} / ${graceState.maxGraceTokens}',
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(
                    context,
                    'Days Until Reset',
                    '$daysUntilReset days',
                  ),
                  if (graceState.lastResetDate != null) ...
                    [
                    SizedBox(height: DesignSystem.spacing8),
                    _buildInfoRow(
                      context,
                      'Last Reset',
                      '${graceState.lastResetDate?.day}/${graceState.lastResetDate?.month}/${graceState.lastResetDate?.year}',
                    ),
                  ],
                  SizedBox(height: DesignSystem.spacing16),
                  Divider(color: AppColors.neonBlue.withValues(alpha: 0.2)),
                  SizedBox(height: DesignSystem.spacing8),
                  const Text(
                    'Grace tokens allow you to skip a day without breaking your streak. They reset every week.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing16),
          
          // Statistics Section
          IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Padding(
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: DesignSystem.spacing8),
                      Text(
                        'Statistics',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  _buildInfoRow(
                    context,
                    'Total Domains',
                    '${domainState.domains.length}',
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(
                    context,
                    'Active Domains',
                    '${domainState.activeDomains.length}',
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(
                    context,
                    'Total Tasks',
                    '${taskState.tasks.length}',
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(
                    context,
                    'Recurring Tasks',
                    '${taskState.recurringTasks.length}',
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing16),
          
          // Domain Strengths Section
          IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Padding(
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: DesignSystem.spacing8),
                      Text(
                        'Domain Strengths',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  if (domainState.domains.isEmpty)
                    const Text(
                      'No domains yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    ...domainState.domains.map((domain) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildInfoRow(
                            context,
                            domain.name,
                            'Strength: ${domain.strength}',
                          ),
                        )),
                ],
              ),
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing16),

          // Data Safety Section
          IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Padding(
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.security,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: DesignSystem.spacing8),
                      const Text(
                        'Data Safety',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  const Text(
                    'Export a full backup of your domains, tasks, logs, rivals and fuel vault to a JSON file.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  IgrisButton(
                    text: 'Backup Data',
                    onPressed: _isBackingUp ? null : _runBackup,
                    variant: IgrisButtonVariant.primary,
                    isLoading: _isBackingUp,
                    icon: Icons.upload_file,
                    fullWidth: true,
                  ),
                  SizedBox(height: DesignSystem.spacing12),
                  IgrisButton(
                    text: 'Restore Backup',
                    onPressed: _isRestoring ? null : _runRestore,
                    variant: IgrisButtonVariant.outline,
                    isLoading: _isRestoring,
                    icon: Icons.download,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing16),

          // App Info Section
          IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Padding(
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: DesignSystem.spacing8),
                      Text(
                        'About',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  _buildInfoRow(context, 'App Name', 'Igris'),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(context, 'Version', _appVersion.isEmpty ? '—' : _appVersion),
                  SizedBox(height: DesignSystem.spacing16),
                  Divider(color: AppColors.neonBlue.withValues(alpha: 0.2)),
                  SizedBox(height: DesignSystem.spacing8),
                  const Text(
                    'A proximal productivity and identity-tracking app.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext ctx, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.neonBlue,
          ),
        ),
      ],
    );
  }
}
