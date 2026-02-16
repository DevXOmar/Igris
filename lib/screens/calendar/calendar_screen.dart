import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/daily_log_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/domain_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/theme/app_theme.dart';

/// Calendar screen showing monthly view with task completion indicators
/// Professional dark theme with controlled red accents
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
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
                // Today decoration - deep blue circle
                todayDecoration: BoxDecoration(
                  color: AppTheme.deepBlue,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                // Selected day - blood red outline
                selectedDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.bloodRedActive,
                    width: 2,
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
                // Marker (completion indicator)
                markerDecoration: const BoxDecoration(
                  color: AppTheme.bloodRedActive,
                  shape: BoxShape.circle,
                ),
                markersAlignment: Alignment.bottomCenter,
                markerSize: 6,
                markerMargin: const EdgeInsets.only(top: 4),
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
                markerBuilder: (context, date, events) {
                  final log = ref.read(dailyLogProvider.notifier).getLogForDate(date);
                  if (log != null && log.completedTaskIds.isNotEmpty) {
                    return Positioned(
                      bottom: 2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.bloodRedActive,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const Divider(),
            Expanded(
              child: _selectedDay == null
                  ? Center(
                      child: Text(
                        'Select a day to view details',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : _buildDayDetails(_selectedDay!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetails(DateTime day) {
    final log = ref.read(dailyLogProvider.notifier).getLogForDate(day);
    final taskState = ref.watch(taskProvider);
    final domainState = ref.watch(domainProvider);
    final dateFormatted = app_date_utils.DateUtils.formatDateLong(day);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormatted,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (log == null || log.completedTaskIds.isEmpty)
            Text(
              'No tasks completed on this day',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.bloodRedActive,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Completed Tasks: ${log.completedTaskIds.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (log.graceUsed) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.deepBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.deepBlue,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: AppTheme.deepBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Grace token used',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.deepBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Progress by Domain',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // List of domains with progress
                  Expanded(
                    child: _buildDomainProgressList(log, taskState, domainState),
                  ),
                ],
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
      return const Center(
        child: Text('No domain data available'),
      );
    }
    
    return ListView.builder(
      itemCount: domainsWithTasks.length,
      itemBuilder: (context, index) {
        final domain = domainsWithTasks[index]!;
        final completedTaskIds = domainTaskMap[domain.id] ?? [];
        final totalDomainTasks = taskState.getTasksByDomain(domain.id).length;
        final completedCount = completedTaskIds.length;
        final progress = totalDomainTasks > 0 ? completedCount / totalDomainTasks : 0.0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        domain.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: progress == 1.0
                            ? AppTheme.bloodRed.withValues(alpha: 0.2)
                            : AppTheme.deepBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: progress == 1.0 ? AppTheme.bloodRed : AppTheme.deepBlue,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$completedCount/$totalDomainTasks',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: progress == 1.0 ? AppTheme.bloodRedActive : AppTheme.deepBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar with theme colors
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppTheme.backgroundElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppTheme.bloodRedActive : AppTheme.deepBlue,
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
