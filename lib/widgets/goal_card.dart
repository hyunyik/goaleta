import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:goaleta/models/goal.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/utils/eta_calculator.dart';

class GoalCard extends ConsumerWidget {
  final Goal goal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GoalCard({
    required this.goal,
    required this.onTap,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final completedAsyncValue = ref.watch(completedAmountProvider(goal.id));
        final logsAsyncValue = ref.watch(logsProvider(goal.id));

        return completedAsyncValue.when(
          loading: () => _buildCardContent(
            context,
            completedAmount: 0,
            logs: [],
            isLoading: true,
          ),
          error: (err, stack) => _buildCardContent(
            context,
            completedAmount: 0,
            logs: [],
            isLoading: false,
          ),
          data: (completedAmount) {
            final logs = logsAsyncValue.maybeWhen(
              data: (l) => l,
              orElse: () => <LogEntry>[],
            );
            return _buildCardContent(
              context,
              completedAmount: completedAmount,
              logs: logs,
              isLoading: false,
            );
          },
        );
      },
    );
  }

  Widget _buildCardContent(
    BuildContext context, {
    required double completedAmount,
    required List<LogEntry> logs,
    required bool isLoading,
  }) {
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

    final dateFormatter = DateFormat('yyyy.MM.dd');
    final etaText = remainingDays == 0
        ? '완료됨'
        : remainingDays == 1
            ? '내일'
            : '$remainingDays일 남음';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목 + 카테고리 아이콘 + 메뉴 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 카테고리 아이콘
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: goal.category.getColor(context).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      goal.category.icon,
                      size: 20,
                      color: goal.category.getColor(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirm(context);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 진행률 바
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 진행률(%) · 남은 양
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '남음: ${remaining.toStringAsFixed(1)} ${goal.unit}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 예상 완료일(ETA) 또는 n일 남음
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ETA: ${dateFormatter.format(estimatedDate)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      etaText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표 삭제'),
        content: Text('${goal.title}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
