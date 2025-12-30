import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:goaleta/models/goal.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/utils/eta_calculator.dart';
import 'package:goaleta/widgets/add_log_sheet.dart';

class GoalDetailScreen extends ConsumerWidget {
  final Goal goal;

  const GoalDetailScreen({required this.goal, Key? key}) : super(key: key);

  String? _getBackgroundImage() {
    // Map category to background image - same as GoalCard
    switch (goal.category) {
      case GoalCategory.reading:
        return 'assets/images/reading.png';
      case GoalCategory.study:
        return 'assets/images/study.png';
      case GoalCategory.fitness:
        return 'assets/images/fitness.png';
      case GoalCategory.writing:
        return 'assets/images/writing.png';
      case GoalCategory.practice:
        return 'assets/images/practice.png';
      case GoalCategory.custom:
        return 'assets/images/custom.png';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsyncValue = ref.watch(completedAmountProvider(goal.id));
    final logsAsyncValue = ref.watch(logsProvider(goal.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: completedAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('오류 발생: $err')),
        data: (completedAmount) {
          final logs = logsAsyncValue.maybeWhen(
            data: (l) => l,
            orElse: () => [],
          );

          final remaining = goal.getRemainingAmount(completedAmount);
          final percentage = goal.getProgressPercentage(completedAmount);

          final etaData = ETACalculator.calculateSimpleAverageETA(
            completedAmount: completedAmount,
            totalAmount: goal.totalAmount,
            startDate: goal.startDate,
            logs: logs.cast<LogEntry>(),
            excludeWeekends: goal.excludeWeekends,
          );

          final estimatedDate = etaData['estimatedDate'] as DateTime;
          final remainingDays = etaData['remainingDays'] as int;
          final dailyAverage = etaData['dailyAverage'] as double;

          final dateFormatter = DateFormat('yyyy.MM.dd');
          final backgroundImage = _getBackgroundImage();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(logsProvider(goal.id));
              ref.invalidate(completedAmountProvider(goal.id));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                // 상단: 남은 양 및 ETA with background image
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    image: backgroundImage != null
                        ? DecorationImage(
                            image: AssetImage(backgroundImage),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.4),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                    gradient: backgroundImage == null
                        ? LinearGradient(
                            colors: [
                              goal.category.getColor(context).withOpacity(0.7),
                              goal.category.getColor(context),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 남은 양 - 큰 숫자
                      Text(
                        remaining.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${goal.unit} 남음',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ETA 정보 with color-coded status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildETAItem(
                              context,
                              '예상 완료일',
                              dateFormatter.format(estimatedDate),
                              _getETAStatusColor(context, remainingDays, dailyAverage, remaining),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.black.withOpacity(0.1),
                            ),
                            _buildETAItem(
                              context,
                              '남은 일수',
                              remainingDays == 0 ? '완료' : '$remainingDays일',
                              _getETAStatusColor(context, remainingDays, dailyAverage, remaining),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Summary statistics card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: goal.category.getColor(context).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: goal.category.getColor(context).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          Icons.event_note,
                          '총 기록',
                          '${logs.length}일',
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.black.withOpacity(0.1),
                        ),
                        _buildStatItem(
                          context,
                          Icons.star,
                          '최고 기록',
                          logs.isEmpty ? '0' : logs.map((l) => l.amount).reduce((a, b) => a > b ? a : b).toStringAsFixed(0),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.black.withOpacity(0.1),
                        ),
                        _buildStatItem(
                          context,
                          Icons.timeline,
                          '활동 일수',
                          '${_getUniqueDaysCount(logs.cast<LogEntry>())}일',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 진행 상황
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 20,
                            color: Colors.black.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '진행 상황',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 12,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            goal.category.getColor(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${completedAmount.toStringAsFixed(0)} / ${goal.totalAmount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: goal.category.getColor(context).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '일평균: ${dailyAverage.toStringAsFixed(2)} ${goal.unit}/일',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 최근 14일 기록 차트 (리스트 형태)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 20,
                            color: Colors.black.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '최근 14일 기록',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRecentDaysChart(context, logs.cast<LogEntry>()),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 기록 리스트
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 20,
                                color: Colors.black.withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '기록 (${logs.length}건)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              _showAddLogSheet(context, ref);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (logs.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.edit_calendar,
                                  size: 64,
                                  color: Colors.black.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '아직 기록이 없습니다',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black.withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '아래 + 버튼을 눌러 기록을 추가해보세요',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return _buildLogItem(context, log, ref);
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddLogSheet(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildETAItem(BuildContext context, String label, String value, Color statusColor) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.black.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentDaysChart(BuildContext context, List<LogEntry> logs) {
    final data = ETACalculator.getRecentDaysData(logs: logs, days: 14);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final maxHeight = maxValue > 0 ? maxValue : 1.0;

    final now = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        data.length,
        (index) {
          final value = data[index];
          final height = (value / maxHeight * 100).clamp(8.0, 100.0);
          // Calculate color intensity based on value
          final colorOpacity = value > 0 ? (value / maxValue * 0.7 + 0.3).clamp(0.3, 1.0) : 0.15;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Count above bar
                  Text(
                    value > 0 ? value.toStringAsFixed(0) : '',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Bar with gradient color based on value
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: goal.category.getColor(context).withOpacity(colorOpacity),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, LogEntry log, WidgetRef ref) {
    final dateStr = DateFormat('MM.dd E', 'ko_KR').format(log.logDate);

    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('기록 삭제'),
              content: const Text('이 기록을 삭제하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('삭제'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        ref.read(logNotifierProvider(goal.id).notifier).deleteLog(log.id);
        ref.invalidate(logsProvider(goal.id));
        ref.invalidate(completedAmountProvider(goal.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date
            SizedBox(
              width: 70,
              child: Text(
                dateStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Vertical separator
            Container(
              width: 1,
              height: 30,
              color: Colors.black.withOpacity(0.1),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            // Amount
            Expanded(
              child: Text(
                '${log.amount.toStringAsFixed(0)} ${goal.unit}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Note or menu
            if (log.note != null && log.note!.isNotEmpty)
              Expanded(
                flex: 2,
                child: Text(
                  log.note!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const SizedBox(width: 8),
            // Menu button
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: Colors.black.withOpacity(0.4),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditLogSheet(context, log, ref);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'edit', child: Text('수정')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteLogDialog(BuildContext context, LogEntry log, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              ref.read(logNotifierProvider(goal.id).notifier).deleteLog(log.id);
              ref.invalidate(logsProvider(goal.id));
              ref.invalidate(completedAmountProvider(goal.id));
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAddLogSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => AddLogBottomSheet(
        goalId: goal.id,
        unit: goal.unit,
        onSave: (log) {
          HapticFeedback.mediumImpact();
          ref.read(logNotifierProvider(goal.id).notifier).addLog(log);
          ref.invalidate(logsProvider(goal.id));
          ref.invalidate(completedAmountProvider(goal.id));
        },
      ),
    );
  }

  void _showEditLogSheet(BuildContext context, LogEntry log, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => AddLogBottomSheet(
        goalId: goal.id,
        unit: goal.unit,
        existingLog: log,
        onSave: (updatedLog) {
          ref.read(logNotifierProvider(goal.id).notifier).updateLog(updatedLog);
          ref.invalidate(logsProvider(goal.id));
          ref.invalidate(completedAmountProvider(goal.id));
        },
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: goal.category.getColor(context)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  int _getUniqueDaysCount(List<LogEntry> logs) {
    final uniqueDates = logs.map((log) {
      final date = log.logDate;
      return DateTime(date.year, date.month, date.day);
    }).toSet();
    return uniqueDates.length;
  }

  Color _getETAStatusColor(BuildContext context, int remainingDays, double dailyAverage, double remaining) {
    final daysNeeded = dailyAverage > 0 ? (remaining / dailyAverage).ceil() : 999;
    if (remainingDays == 0) return Colors.green;
    if (daysNeeded <= remainingDays) return Colors.green; // On track
    if (daysNeeded <= remainingDays * 1.5) return Colors.orange; // Slightly behind
    return Colors.red; // Far behind
  }
}
