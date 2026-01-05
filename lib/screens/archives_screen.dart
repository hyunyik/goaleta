import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goaleta/models/goal.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/screens/goal_detail_screen.dart';
import 'package:intl/intl.dart';

// Provider for archived goals
final archivedGoalsProvider = Provider<List<Goal>>((ref) {
  final goalsAsync = ref.watch(goalsProvider);
  return goalsAsync.maybeWhen(
    data: (goals) => goals.where((g) => g.isArchived).toList()
      ..sort((a, b) => (b.archivedAt ?? b.completedAt ?? b.createdAt)
          .compareTo(a.archivedAt ?? a.completedAt ?? a.createdAt)),
    orElse: () => [],
  );
});

// Statistics provider for archives
final archiveStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final archivedGoals = ref.watch(archivedGoalsProvider);
  
  final now = DateTime.now();
  final thisMonth = archivedGoals.where((g) {
    final archivedDate = g.archivedAt ?? g.completedAt;
    return archivedDate != null &&
        archivedDate.year == now.year &&
        archivedDate.month == now.month;
  }).length;
  
  final thisYear = archivedGoals.where((g) {
    final archivedDate = g.archivedAt ?? g.completedAt;
    return archivedDate != null && archivedDate.year == now.year;
  }).length;
  
  // Group by month
  final monthlyStats = <String, int>{};
  for (final goal in archivedGoals) {
    final archivedDate = goal.archivedAt ?? goal.completedAt;
    if (archivedDate != null) {
      final key = DateFormat('yyyy-MM').format(archivedDate);
      monthlyStats[key] = (monthlyStats[key] ?? 0) + 1;
    }
  }
  
  // Group by category
  final categoryStats = <GoalCategory, int>{};
  for (final goal in archivedGoals) {
    categoryStats[goal.category] = (categoryStats[goal.category] ?? 0) + 1;
  }
  
  return {
    'total': archivedGoals.length,
    'thisMonth': thisMonth,
    'thisYear': thisYear,
    'monthlyStats': monthlyStats,
    'categoryStats': categoryStats,
  };
});

class ArchivesScreen extends ConsumerWidget {
  const ArchivesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedGoals = ref.watch(archivedGoalsProvider);
    final stats = ref.watch(archiveStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('보관함'),
        elevation: 0,
      ),
      body: SafeArea(
        child: archivedGoals.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '아직 완료된 목표가 없습니다',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '목표를 달성하면 여기에 보관됩니다',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Stats
                  _buildOverviewSection(context, stats),
                  
                  const SizedBox(height: 16),
                  
                  // Monthly breakdown
                  if (stats['monthlyStats'].isNotEmpty)
                    _buildMonthlyBreakdown(context, stats['monthlyStats']),
                  
                  const SizedBox(height: 16),
                  
                  // Category breakdown
                  if (stats['categoryStats'].isNotEmpty)
                    _buildCategoryBreakdown(context, stats['categoryStats']),
                  
                  const SizedBox(height: 16),
                  
                  // Archived goals list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '완료된 목표 목록',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: archivedGoals.length,
                    itemBuilder: (context, index) {
                      final goal = archivedGoals[index];
                      return _buildArchivedGoalCard(context, ref, goal);
                    },
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                '달성 현황',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                context,
                '총 달성',
                '${stats['total']}개',
                Icons.check_circle,
              ),
              _buildStatCard(
                context,
                '이번 달',
                '${stats['thisMonth']}개',
                Icons.calendar_today,
              ),
              _buildStatCard(
                context,
                '올해',
                '${stats['thisYear']}개',
                Icons.calendar_month,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
        ),
      ],
    );
  }

  Widget _buildMonthlyBreakdown(
    BuildContext context,
    Map<String, int> monthlyStats,
  ) {
    final sortedEntries = monthlyStats.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final recentMonths = sortedEntries.take(6).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '월별 달성 현황',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...recentMonths.map((entry) {
            final date = DateTime.parse('${entry.key}-01');
            final monthLabel = DateFormat('yyyy년 MM월').format(date);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      monthLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: entry.value / (monthlyStats.values.reduce((a, b) => a > b ? a : b)),
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entry.value}개',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    BuildContext context,
    Map<GoalCategory, int> categoryStats,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '카테고리별 달성',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryStats.entries.map((entry) {
              return Chip(
                avatar: Icon(
                  entry.key.icon,
                  size: 18,
                  color: entry.key.getColor(context),
                ),
                label: Text('${entry.key.displayName}: ${entry.value}개'),
                backgroundColor: entry.key.getColor(context).withOpacity(0.1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedGoalCard(BuildContext context, WidgetRef ref, Goal goal) {
    final archivedDate = goal.archivedAt ?? goal.completedAt ?? goal.createdAt;
    final duration = (goal.completedAt ?? goal.archivedAt ?? DateTime.now())
        .difference(goal.startDate)
        .inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GoalDetailScreen(goal: goal, isReadOnly: true),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: goal.category.getColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      goal.category.icon,
                      color: goal.category.getColor(context),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          DateFormat('yyyy.MM.dd 완료').format(archivedDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '달성량',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(goal.totalAmount - goal.startingAmount).toStringAsFixed(0)} ${goal.unit}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                    Column(
                      children: [
                        Text(
                          '소요 기간',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$duration일',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Delete button
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('업적 삭제'),
                      content: const Text('이 업적을 영구적으로 삭제하시겠습니까?\n삭제된 목표는 복구할 수 없습니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('목표가 삭제되었습니다'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('업적 삭제'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
