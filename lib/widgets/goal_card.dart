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

  const GoalCard({
    required this.goal,
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
    final percentage = goal.getProgressPercentage(completedAmount);

    final etaData = ETACalculator.calculateSimpleAverageETA(
      completedAmount: completedAmount,
      totalAmount: goal.totalAmount,
      startDate: goal.startDate,
      logs: logs,
      excludeWeekends: goal.excludeWeekends,
    );

    final estimatedDate = etaData['estimatedDate'] as DateTime;
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
    DateTime estimatedDate,
    DateFormat dateFormatter,
  ) {
    return SizedBox(
      height: 200,
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
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
              ),
            ),
          ),

          // Bottom 1/3: White background with Percent and ETA
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress %
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: goal.category.getColor(context),
                    ),
                  ),

                  // ETA
                  Text(
                    'ETA ${dateFormatter.format(estimatedDate)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
