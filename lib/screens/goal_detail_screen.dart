import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:goaleta/models/goal.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/utils/eta_calculator.dart';
import 'package:goaleta/widgets/add_log_sheet.dart';
import 'package:goaleta/widgets/running_cat.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const SizedBox
            .shrink(), // Empty title, we'll put it on the background
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle:
            SystemUiOverlayStyle.light, // Light status bar icons
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false, // Don't apply top padding since we extend behind app bar
        child: completedAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('오류 발생: $err')),
          data: (completedAmount) {
          final logs = logsAsyncValue.maybeWhen(
            data: (l) => l,
            orElse: () => [],
          );

          final remaining = goal.getRemainingAmount(completedAmount);
          final percentage = goal.getProgressPercentage(completedAmount);

          final hasRecords = logs.isNotEmpty;

          final etaData = hasRecords
              ? ETACalculator.calculateSimpleAverageETA(
                  completedAmount: completedAmount,
                  totalAmount: goal.totalAmount,
                  startDate: goal.startDate,
                  logs: logs.cast<LogEntry>(),
                  excludeWeekends: goal.excludeWeekends,
                  startingAmount: goal.startingAmount,
                )
              : null;

          final estimatedDate =
              etaData != null ? etaData['estimatedDate'] as DateTime : null;
          final remainingDays =
              etaData != null ? etaData['remainingDays'] as int : null;
          final dailyAverage =
              etaData != null ? etaData['dailyAverage'] as double : null;

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
                  // 상단: Background image header with title and bar chart
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      MediaQuery.of(context).padding.top +
                          56, // Status bar + AppBar height
                      24,
                      32,
                    ),
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
                                goal.category
                                    .getColor(context)
                                    .withOpacity(0.7),
                                goal.category.getColor(context),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title (2 lines max)
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.5,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 8,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 32),

                        // Recent 14 days bar chart (transparent style)
                        _buildTransparentBarChart(
                            context, logs.cast<LogEntry>()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Progress bar with running cat
                        SizedBox(
                          height: 32,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Progress bar at bottom
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  height: 12,
                                  child: ClipRRect(
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
                                ),
                              ),
                              // Running cat
                              _buildRunningCat(
                                context,
                                percentage,
                                dailyAverage ?? 0.0,
                              ),
                            ],
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
                                      ? '${dateFormatter.format(estimatedDate)} (D-${remainingDays ?? 0})'
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
                            mainAxisAlignment: MainAxisAlignment.end,
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Three rounded cards in single row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Progress card
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '진행률',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.black.withOpacity(0.6),
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${completedAmount.toStringAsFixed(0)}/${(goal.totalAmount - goal.startingAmount).toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.black.withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Average record card
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '일평균',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.black.withOpacity(0.6),
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  dailyAverage != null
                                      ? dailyAverage.toStringAsFixed(1)
                                      : '-',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.unit,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.black.withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Best record card
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '최고 기록',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.black.withOpacity(0.6),
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  logs.isEmpty
                                      ? '0'
                                      : logs
                                          .map((l) => l.amount)
                                          .reduce((a, b) => a > b ? a : b)
                                          .toStringAsFixed(0),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal.unit,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.black.withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pace Marker Section (if deadline is set)
                  if (goal.deadline != null && estimatedDate != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.speed,
                                size: 20,
                                color: Colors.black.withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '페이스 메이커',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildPaceMarkerCard(
                            context,
                            estimatedDate,
                            goal.deadline!,
                            remaining,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

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
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.black.withOpacity(0.4),
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
                            padding: const EdgeInsets.only(bottom: 80),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'main_fab',
        onPressed: () {
          _showAddLogSheet(context, ref);
        },
        backgroundColor: goal.category.getColor(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '새 기록',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildETAItem(
      BuildContext context, String label, String value, Color statusColor) {
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

  Widget _buildInfoCard(BuildContext context, {required Widget child}) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRunningCat(
    BuildContext context,
    double percentage,
    double dailyAverage,
  ) {
    // Calculate position based on percentage (with padding for cat size)
    final progress = (percentage / 100).clamp(0.0, 1.0);
    
    return Align(
      alignment: Alignment(
        // Map progress from 0-1 to alignment from -1 to 1
        // Offset slightly to account for cat width
        (progress * 2 - 1).clamp(-1.0, 0.9),
        0.0,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RunningCat(
          progress: progress,
          speed: dailyAverage,
          color: goal.category.getColor(context),
        ),
      ),
    );
  }

  Widget _buildTransparentBarChart(BuildContext context, List<LogEntry> logs) {
    final data = ETACalculator.getRecentDaysData(logs: logs, days: 14);
    final maxValue = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    final maxHeight = maxValue > 0 ? maxValue : 1.0;
    final hasAnyData = data.any((value) => value > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 14일 기록',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: hasAnyData
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    data.length,
                    (index) {
                      final value = data[index];
                      final height =
                          (value / maxHeight * 60).clamp(6.0, 60.0);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Count above bar
                              Text(
                                value > 0 ? value.toStringAsFixed(0) : '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Transparent bar
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(value > 0 ? 0.7 : 0.2),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Center(
                  child: Text(
                    '최근 14일간 기록 없음',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        data.length,
        (index) {
          final value = data[index];
          final height = (value / maxHeight * 100).clamp(8.0, 100.0);
          // Calculate color intensity based on value
          final colorOpacity =
              value > 0 ? (value / maxValue * 0.7 + 0.3).clamp(0.3, 1.0) : 0.15;

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
                      color: goal.category
                          .getColor(context)
                          .withOpacity(colorOpacity),
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
                } else if (value == 'delete') {
                  _showDeleteLogDialog(context, log, ref);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(value: 'delete', child: Text('삭제')),
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

    // Calculate previous cumulative total
    final logsAsyncValue = ref.read(logsProvider(goal.id));
    final logs = logsAsyncValue.maybeWhen(
      data: (l) => l,
      orElse: () => <LogEntry>[],
    );

    // Sort logs by date and calculate cumulative total
    final sortedLogs = List<LogEntry>.from(logs)
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    double previousCumulativeTotal = 0;
    for (final log in sortedLogs) {
      previousCumulativeTotal += log.amount;
    }

    // Find latest log date
    final DateTime? latestLogDate =
        sortedLogs.isNotEmpty ? sortedLogs.last.logDate : null;

    // Get all existing log dates
    final List<DateTime> existingLogDates =
        logs.map((log) => log.logDate).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => AddLogBottomSheet(
        goalId: goal.id,
        unit: goal.unit,
        previousCumulativeTotal: previousCumulativeTotal,
        goalStartDate: goal.startDate,
        startingAmount: goal.startingAmount,
        latestLogDate: latestLogDate,
        existingLogDates: existingLogDates,
        goal: goal,
        onSave: (log) async {
          // Check if a log already exists for this date
          final logsAsyncValue = ref.read(logsProvider(goal.id));
          final logs = logsAsyncValue.maybeWhen(
            data: (l) => l,
            orElse: () => <LogEntry>[],
          );

          final existingLog = logs.firstWhere(
            (l) =>
                l.logDate.year == log.logDate.year &&
                l.logDate.month == log.logDate.month &&
                l.logDate.day == log.logDate.day &&
                l.id != log.id, // Exclude the current log if editing
            orElse: () => LogEntry(goalId: '', amount: -1), // Dummy entry
          );

          if (existingLog.amount != -1) {
            // Log exists for this date, show dialog
            final result = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('기록이 이미 존재합니다'),
                content: Text(
                  '${DateFormat('yyyy.MM.dd').format(log.logDate)}에 이미 ${existingLog.amount.toStringAsFixed(0)} ${goal.unit}의 기록이 있습니다.\n\n새로운 값을 어떻게 처리하시겠습니까?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'cancel'),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'add'),
                    child: const Text('더하기'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'replace'),
                    child: const Text('교체'),
                  ),
                ],
              ),
            );

            if (result == 'add') {
              // Add to existing value
              final updatedLog = existingLog.copyWith(
                amount: existingLog.amount + log.amount,
                note: log.note != null
                    ? '${existingLog.note ?? ''}\n${log.note}'.trim()
                    : existingLog.note,
              );
              HapticFeedback.mediumImpact();
              ref
                  .read(logNotifierProvider(goal.id).notifier)
                  .addLog(updatedLog);
              ref.invalidate(logsProvider(goal.id));
              ref.invalidate(completedAmountProvider(goal.id));
            } else if (result == 'replace') {
              // Replace existing value
              final updatedLog = existingLog.copyWith(
                amount: log.amount,
                note: log.note,
              );
              HapticFeedback.mediumImpact();
              ref
                  .read(logNotifierProvider(goal.id).notifier)
                  .addLog(updatedLog);
              ref.invalidate(logsProvider(goal.id));
              ref.invalidate(completedAmountProvider(goal.id));
            }
            // If 'cancel', do nothing
          } else {
            // No existing log, just add it
            HapticFeedback.mediumImpact();
            ref.read(logNotifierProvider(goal.id).notifier).addLog(log);
            ref.invalidate(logsProvider(goal.id));
            ref.invalidate(completedAmountProvider(goal.id));
          }
        },
      ),
    );
  }

  void _showEditLogSheet(BuildContext context, LogEntry log, WidgetRef ref) {
    // Get all existing log dates for the calendar
    final logsAsyncValue = ref.read(logsProvider(goal.id));
    final logs = logsAsyncValue.maybeWhen(
      data: (l) => l,
      orElse: () => <LogEntry>[],
    );
    final List<DateTime> existingLogDates = logs.map((l) => l.logDate).toList();

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
        goalStartDate: goal.startDate,
        startingAmount: goal.startingAmount,
        existingLogDates: existingLogDates,
        goal: goal,
        onSave: (updatedLog) {
          ref.read(logNotifierProvider(goal.id).notifier).updateLog(updatedLog);
          ref.invalidate(logsProvider(goal.id));
          ref.invalidate(completedAmountProvider(goal.id));
        },
      ),
    );
  }

  Widget _buildPaceMarkerCard(
    BuildContext context,
    DateTime estimatedDate,
    DateTime deadline,
    double remaining,
  ) {
    final difference = estimatedDate.difference(deadline).inDays;
    final daysUntilDeadline = deadline.difference(DateTime.now()).inDays;
    final requiredDailyAmount = daysUntilDeadline > 0 
        ? remaining / daysUntilDeadline 
        : remaining;
    
    final dateFormatter = DateFormat('yyyy.MM.dd');
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (difference > 0) {
      statusColor = Colors.red;
      statusText = '마감일보다 ${difference}일 늦어요';
      statusIcon = Icons.warning_amber_rounded;
    } else if (difference < 0) {
      statusColor = Colors.green;
      statusText = '마감일보다 ${-difference}일 빨라요';
      statusIcon = Icons.check_circle_outline;
    } else {
      statusColor = Colors.orange;
      statusText = '마감일과 동일해요';
      statusIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPaceInfoItem(
                  context,
                  '마감일',
                  dateFormatter.format(deadline),
                  Icons.event,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaceInfoItem(
                  context,
                  '예상 완료일',
                  dateFormatter.format(estimatedDate),
                  Icons.flag,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.speed,
                  color: goal.category.getColor(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '필요 일평균: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
                Text(
                  '${requiredDailyAmount.toStringAsFixed(1)} ${goal.unit}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: goal.category.getColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaceInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, String label, String value) {
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

  Color _getETAStatusColor(BuildContext context, int remainingDays,
      double dailyAverage, double remaining) {
    final daysNeeded =
        dailyAverage > 0 ? (remaining / dailyAverage).ceil() : 999;
    if (remainingDays == 0) return Colors.green;
    if (daysNeeded <= remainingDays) return Colors.green; // On track
    if (daysNeeded <= remainingDays * 1.5)
      return Colors.orange; // Slightly behind
    return Colors.red; // Far behind
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
}
