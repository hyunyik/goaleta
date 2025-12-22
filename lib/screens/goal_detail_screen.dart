import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:goaleta/models/goal.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/utils/eta_calculator.dart';
import 'package:goaleta/widgets/add_log_sheet.dart';

class GoalDetailScreen extends ConsumerWidget {
  final Goal goal;

  const GoalDetailScreen({required this.goal, Key? key}) : super(key: key);

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
            logs: logs,
            excludeWeekends: goal.excludeWeekends,
          );

          final estimatedDate = etaData['estimatedDate'] as DateTime;
          final remainingDays = etaData['remainingDays'] as int;
          final dailyAverage = etaData['dailyAverage'] as double;

          final dateFormatter = DateFormat('yyyy.MM.dd');

          return SingleChildScrollView(
            child: Column(
              children: [
                // 상단: 남은 양 및 ETA
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 남은 양 - 큰 숫자
                      Text(
                        remaining.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${goal.unit} 남음',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ETA 정보
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildETAItem(
                            context,
                            '예상 완료일',
                            dateFormatter.format(estimatedDate),
                          ),
                          _buildETAItem(
                            context,
                            '남은 일수',
                            remainingDays == 0 ? '완료' : '$remainingDays일',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 진행 상황
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '진행 상황',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 12,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${completedAmount.toStringAsFixed(1)} / ${goal.totalAmount}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '일평균: ${dailyAverage.toStringAsFixed(2)} ${goal.unit}/일',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                      Text(
                        '최근 14일 기록',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildRecentDaysChart(context, logs),
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
                          Text(
                            '기록 (${logs.length}건)',
                            style: Theme.of(context).textTheme.titleMedium,
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
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              '아직 기록이 없습니다',
                              style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildETAItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDaysChart(BuildContext context, List<LogEntry> logs) {
    final data = ETACalculator.getRecentDaysData(logs: logs, days: 14);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final maxHeight = maxValue > 0 ? maxValue : 1.0;

    final now = DateTime.now();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          data.length,
          (index) {
            final value = data[index];
            final height = (value / maxHeight * 100).clamp(8.0, 100.0);
            final date = DateTime(
              now.year,
              now.month,
              now.day - (data.length - 1 - index),
            );
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value > 0 ? value.toStringAsFixed(0) : '',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 20,
                    height: height,
                    decoration: BoxDecoration(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.month}/${date.day}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, LogEntry log, WidgetRef ref) {
    final dateFormatter = DateFormat('yyyy.MM.dd (E)', 'ko_KR');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            log.amount.toStringAsFixed(0),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${log.amount.toStringAsFixed(1)} ${goal.unit}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateFormatter.format(log.logDate),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (log.note != null && log.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  log.note!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditLogSheet(context, log, ref);
            } else if (value == 'delete') {
              _showDeleteLogDialog(context, log, ref);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(value: 'edit', child: Text('수정')),
            const PopupMenuItem(value: 'delete', child: Text('삭제')),
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
              Navigator.pop(context);
              ref.read(logNotifierProvider(goal.id).notifier).deleteLog(log.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('기록이 삭제되었습니다'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAddLogSheet(BuildContext context, WidgetRef ref) {
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
          ref.read(logNotifierProvider(goal.id).notifier).addLog(log);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('기록이 추가되었습니다'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
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
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('기록이 수정되었습니다'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
