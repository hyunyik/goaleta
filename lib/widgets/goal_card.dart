import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:goaleta/models/goal.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/utils/eta_calculator.dart';
import 'package:goaleta/screens/goal_detail_screen.dart';
import 'package:animations/animations.dart';

class GoalCard extends ConsumerWidget {
  final Goal goal;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const GoalCard({
    required this.goal,
    required this.onDelete,
    required this.onEdit,
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
    final percentage = goal.getProgressPercentage(completedAmount);
    final formattedCompleted = completedAmount % 1 == 0 
        ? completedAmount.toStringAsFixed(0) 
        : completedAmount.toString();
    final formattedTotal = goal.totalAmount % 1 == 0 
        ? goal.totalAmount.toStringAsFixed(0) 
        : goal.totalAmount.toString();

    final etaData = ETACalculator.calculateSimpleAverageETA(
      cumulativeAmount: completedAmount,
      totalAmount: goal.totalAmount,
      startDate: goal.startDate,
      logs: logs,
      excludeWeekends: goal.excludeWeekends,
      startingAmount: goal.startingAmount,
    );

    final estimatedDate =
        etaData != null ? etaData['estimatedDate'] as DateTime : null;
    final dateFormatter = DateFormat('yyyy.MM.dd');

    // Background image path based on category
    final backgroundImage = _getBackgroundImage();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: const Duration(milliseconds: 500),
        closedElevation: 4,
        openElevation: 0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        openShape: const RoundedRectangleBorder(),
        closedColor: Colors.white,
        openColor: Theme.of(context).colorScheme.surface,
        middleColor: Theme.of(context).colorScheme.surface,
        closedBuilder: (context, openContainer) {
          return _buildClosedCard(
            context,
            backgroundImage,
            percentage,
            estimatedDate,
            dateFormatter,
            formattedCompleted,
            formattedTotal,
          );
        },
        openBuilder: (context, closeContainer) {
          return GoalDetailScreen(goal: goal);
        },
      ),
    );
  }

  Widget _buildClosedCard(
    BuildContext context,
    String? backgroundImage,
    double percentage,
    DateTime? estimatedDate,
    DateFormat dateFormatter,
    String formattedCompleted,
    String formattedTotal,
  ) {
    return SizedBox(
      height: 240,
      child: Column(
        children: [
          // Top 2/3: Background image with title
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: backgroundImage != null
                    ? DecorationImage(
                        image: AssetImage(backgroundImage),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3),
                          BlendMode.darken,
                        ),
                      )
                    : null,
                gradient: backgroundImage == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          goal.category.getColor(context).withOpacity(0.7),
                          goal.category.getColor(context),
                        ],
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Three dots menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          size: 24, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          _showDeleteConfirm(context);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('수정'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20),
                              SizedBox(width: 8),
                              Text('삭제'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom section: Progress bar and info
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Percentage and amount info above progress bar
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${percentage.toStringAsFixed(0)}% ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: goal.category.getColor(context),
                          ),
                        ),
                        TextSpan(
                          text: '($formattedCompleted/$formattedTotal ${goal.unit})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.category.getColor(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Start date and ETA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Start date
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormatter.format(goal.startDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // ETA
                    Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estimatedDate != null
                              ? '${dateFormatter.format(estimatedDate)} (D-${estimatedDate.difference(DateTime.now()).inDays})'
                              : '-',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Deadline info (if set)
                if (goal.deadline != null && estimatedDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox.shrink(),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '마감: ${dateFormatter.format(goal.deadline!)} ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '(${_getDeadlineDifference(estimatedDate, goal.deadline!)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getDeadlineColor(estimatedDate, goal.deadline!),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDeadlineDifference(DateTime eta, DateTime deadline) {
    final difference = eta.difference(deadline).inDays;
    if (difference > 0) {
      return '+$difference일';
    } else if (difference < 0) {
      return '${difference}일';
    } else {
      return '동일';
    }
  }

  Color _getDeadlineColor(DateTime eta, DateTime deadline) {
    final difference = eta.difference(deadline).inDays;
    if (difference > 0) {
      return Colors.red; // Behind schedule
    } else if (difference < 0) {
      return Colors.green; // Ahead of schedule
    } else {
      return Colors.orange; // On schedule
    }
  }

  String? _getBackgroundImage() {
    // Map category to background image
    // You can add your PNG files to assets/images/ folder
    // and update these paths accordingly
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
        return 'assets/images/custom.png'; // Use gradient for custom category
    }
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
