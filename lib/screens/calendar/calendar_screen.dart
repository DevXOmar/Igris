import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/daily_log_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/domain_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../core/theme/igris_animations.dart';
import '../../widgets/layout/igris_screen_scaffold.dart';
import '../../widgets/ui/igris_ui.dart';

/// Calendar screen with Igris UI integration
/// - TableCalendar wrapped in IgrisCard
/// - Today: neonBlue filled, Selected: bloodRed outline
/// - Completed tasks grouped by domain with gold accents
/// 
/// Animations:
/// - Task list fades in when date selection changes
/// - No looping animations on calendar cells
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return IgrisScreenScaffold(
      title: 'Calendar',
      applyPadding: false,
      child: Column(
        children: [
          // Calendar wrapped in IgrisCard for consistent styling
          Padding(
            padding: DesignSystem.paddingAll16,
            child: IgrisCard(
              child: TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                // Today: neonBlue filled circle (Igris primary accent)
                todayDecoration: BoxDecoration(
                  color: AppColors.neonBlue,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.backgroundPrimary,
                  fontWeight: FontWeight.bold,
                ),
                // Selected: bloodRed outline (not fill)
                selectedDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.bloodRed,
                    width: 2.5,
                  ),
                ),
                selectedTextStyle: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                // Default day styling
                defaultTextStyle: const TextStyle(
                  color: AppTheme.textPrimary,
                ),
                weekendTextStyle: TextStyle(
                  color: AppTheme.textSecondary,
                ),
                outsideTextStyle: TextStyle(
                  color: AppTheme.textMuted,
                ),
                // Marker removed - custom builder adds glowing dot
                markersAlignment: Alignment.bottomCenter,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppTheme.textPrimary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppTheme.textPrimary,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                // Completed day: glowing neonBlue dot
                markerBuilder: (context, date, events) {
                  final log = ref.read(dailyLogProvider.notifier).getLogForDate(date);
                  if (log != null && log.completedTaskIds.isNotEmpty) {
                    return Positioned(
                      bottom: 2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonBlue.withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            ),
          ),
          SizedBox(height: DesignSystem.spacing16),
          // Day details section
          Expanded(
            child: _selectedDay == null
                ? Center(
                    child: Text(
                      'Select a day to view completed tasks',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : _buildDayDetails(_selectedDay!),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetails(DateTime day) {
    final log = ref.read(dailyLogProvider.notifier).getLogForDate(day);
    final taskState = ref.watch(taskProvider);
    final domainState = ref.watch(domainProvider);
    final dateFormatted = app_date_utils.DateUtils.formatDateLong(day);

    return Padding(
      padding: DesignSystem.paddingH16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header with gold accent
          Text(
            dateFormatted,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: DesignSystem.spacing16),
          
          if (log == null || log.completedTaskIds.isEmpty)
            Center(
              child: Padding(
                padding: DesignSystem.paddingAll24,
                child: Text(
                  'No tasks completed on this day',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                // Fade-in animation on date change (key forces re-animation)
                child: Column(
                  key: ValueKey('tasks_${day.toString()}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Completion summary card
                    IgrisCard(
                      variant: IgrisCardVariant.surface,
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.neonBlue,
                            size: 24,
                          ),
                          SizedBox(width: DesignSystem.spacing12),
                          Text(
                            'Completed Tasks: ${log.completedTaskIds.length}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Grace token display
                    if (log.graceUsed) ...[
                      SizedBox(height: DesignSystem.spacing12),
                      IgrisCard(
                        variant: IgrisCardVariant.elevated,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 20,
                              color: AppColors.deepBlue,
                            ),
                            SizedBox(width: DesignSystem.spacing8),
                            Text(
                              'Grace token used',
                              style: TextStyle(
                                color: AppColors.deepBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: DesignSystem.spacing24),
                    
                    // Domain section header with gold accent
                    Text(
                      'Progress by Domain',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: DesignSystem.spacing16),
                    
                    // List of domains with progress
                    _buildDomainProgressList(log, taskState, domainState),
                  ],
                ).igrisFadeIn(), // Fade-in when date changes (re-animated via key)
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDomainProgressList(
    dynamic log,
    TaskState taskState,
    DomainState domainState,
  ) {
    // Group completed tasks by domain
    final Map<String, List<String>> domainTaskMap = {};
    
    for (final taskId in log.completedTaskIds) {
      final task = taskState.getTaskById(taskId);
      if (task != null) {
        domainTaskMap.putIfAbsent(task.domainId, () => []).add(taskId);
      }
    }
    
    // Get all domains that have completed tasks
    final domainsWithTasks = domainTaskMap.keys
        .map((domainId) => domainState.getDomainById(domainId))
        .where((domain) => domain != null)
        .toList();
    
    if (domainsWithTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: DesignSystem.paddingAll24,
          child: Text(
            'No domain data available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: domainsWithTasks.length,
      itemBuilder: (context, index) {
        final domain = domainsWithTasks[index]!;
        final completedTaskIds = domainTaskMap[domain.id] ?? [];
        final totalDomainTasks = taskState.getTasksByDomain(domain.id).length;
        final completedCount = completedTaskIds.length;
        final progress = totalDomainTasks > 0 ? completedCount / totalDomainTasks : 0.0;
        
        return Padding(
          padding: EdgeInsets.only(bottom: DesignSystem.spacing12),
          child: IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        domain.name,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacing12,
                        vertical: DesignSystem.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: progress == 1.0
                            ? AppColors.bloodRed.withValues(alpha: 0.15)
                            : AppColors.neonBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: progress == 1.0 ? AppColors.bloodRed : AppColors.neonBlue,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$completedCount/$totalDomainTasks',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: progress == 1.0 ? AppColors.bloodRed : AppColors.neonBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignSystem.spacing12),
                // Progress bar with Igris colors
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.backgroundElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppColors.bloodRed : AppColors.neonBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
