import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/widgets/goal_card.dart';
import 'package:goaleta/widgets/add_edit_goal_sheet.dart';
import 'package:goaleta/models/goal.dart';
import 'package:goaleta/screens/archives_screen.dart';
import 'package:goaleta/screens/settings_screen.dart';
import 'dart:math';

// Provider for selected category filter
final selectedCategoryProvider = StateProvider<GoalCategory?>((ref) => null);

// Sort options
enum SortOption {
  createdDesc('생성일 (최신순)', Icons.access_time),
  createdAsc('생성일 (오래된순)', Icons.history),
  progressDesc('진행률 (높은순)', Icons.trending_up),
  progressAsc('진행률 (낮은순)', Icons.trending_down);

  final String label;
  final IconData icon;
  const SortOption(this.label, this.icon);
}

// Provider for selected sort option
final selectedSortProvider = StateProvider<SortOption>((ref) => SortOption.createdDesc);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '좋은 아침이에요! 오늘도 화이팅 💪';
    } else if (hour < 18) {
      return '오늘도 열심히 하고 있네요! 👏';
    } else {
      return '오늘 하루도 수고하셨어요! 🌙';
    }
  }

  String _getRandomSubtitle() {
    final subtitles = [
      '목표를 향해 한 걸음씩 나아가요',
      '작은 노력이 큰 변화를 만듭니다',
      '꾸준함이 성공의 비결이에요',
      '오늘의 기록이 내일의 성과가 됩니다',
      '당신의 노력은 헛되지 않아요',
      '매일매일이 성장의 기회입니다',
      '포기하지 마세요, 거의 다 왔어요',
      '작은 성취도 축하할 만한 일이에요',
    ];
    final random = Random();
    return subtitles[random.nextInt(subtitles.length)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsyncValue = ref.watch(goalsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final archiveStats = ref.watch(archiveStatsProvider);
    final alarmEnabled = ref.watch(alarmEnabledProvider);
    final alarmTime = ref.watch(alarmTimeProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side: Greeting and achievements
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getGreetingMessage(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      _getRandomSubtitle(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Achievement summary with all chip buttons inline
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                        Icon(
                          Icons.emoji_events,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '이번 달: ${archiveStats['thisMonth']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '올 해: ${archiveStats['thisYear']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Archives chip button
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ArchivesScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.archive_outlined,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '보관함',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Alarm chip button
                        InkWell(
                          onTap: () {
                            // If no alarm time set, open settings
                            if (alarmTime == null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            } else {
                              // Quick toggle
                              ref.read(alarmEnabledProvider.notifier).state = !alarmEnabled;
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: alarmEnabled
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  alarmEnabled ? Icons.notifications_active : Icons.notifications_off,
                                  size: 12,
                                  color: alarmEnabled
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '알림',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: alarmEnabled
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // More chip button
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.more_horiz,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
            // Right side: Cat logo (bigger, aligned with goal cards)
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.3,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        titleSpacing: 0,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: goalsAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '오류 발생',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$err',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        data: (goals) {
          // Filter out archived goals
          final activeGoals = goals.where((g) => !g.isArchived).toList();
          
          if (activeGoals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 목표가 없습니다',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '새로운 목표를 추가해보세요',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          // Filter goals by selected category
          var filteredGoals = selectedCategory == null
              ? activeGoals
              : activeGoals.where((g) => g.category == selectedCategory).toList();

          // Apply sorting
          final sortOption = ref.watch(selectedSortProvider);
          filteredGoals = _sortGoals(filteredGoals, sortOption, ref);

          return Column(
            children: [
              // Category filter chips
              _buildCategoryChips(context, ref, activeGoals),
              // Sort selector
              _buildSortSelector(context, ref),
              // Goal list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredGoals.length,
                  itemBuilder: (context, index) {
                    final goal = filteredGoals[index];
                    return GoalCard(
                      key: ValueKey(goal.id),
                      goal: goal,
                      onDelete: () {
                        ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('목표가 삭제되었습니다'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddGoalSheet(context, ref);
        },
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCategoryChips(BuildContext context, WidgetRef ref, List<Goal> goals) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    // Count goals by category
    final categoryCounts = <GoalCategory?, int>{};
    categoryCounts[null] = goals.length; // All
    for (final category in GoalCategory.values) {
      categoryCounts[category] = goals.where((g) => g.category == category).length;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // All chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: selectedCategory == null,
              label: Text('전체: ${categoryCounts[null]}'),
              onSelected: (selected) {
                ref.read(selectedCategoryProvider.notifier).state = null;
              },
            ),
          ),
          // Category chips (only show if count > 0)
          ...GoalCategory.values.where((category) {
            final count = categoryCounts[category] ?? 0;
            return count > 0;
          }).map((category) {
            final count = categoryCounts[category] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                selected: selectedCategory == category,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon, size: 16),
                    const SizedBox(width: 4),
                    Text('${category.displayName}: $count'),
                  ],
                ),
                onSelected: (selected) {
                  ref.read(selectedCategoryProvider.notifier).state =
                      selected ? category : null;
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<Goal> _sortGoals(List<Goal> goals, SortOption sortOption, WidgetRef ref) {
    final sorted = List<Goal>.from(goals);
    
    switch (sortOption) {
      case SortOption.createdDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.createdAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.progressDesc:
      case SortOption.progressAsc:
        // For progress sorting, get completed amounts synchronously
        final progressMap = <String, double>{};
        for (final goal in goals) {
          final completedAsync = ref.read(completedAmountProvider(goal.id));
          final completed = completedAsync.maybeWhen(
            data: (amount) => amount,
            orElse: () => 0.0,
          );
          progressMap[goal.id] = goal.getProgressPercentage(completed);
        }
        
        if (sortOption == SortOption.progressDesc) {
          sorted.sort((a, b) => (progressMap[b.id] ?? 0).compareTo(progressMap[a.id] ?? 0));
        } else {
          sorted.sort((a, b) => (progressMap[a.id] ?? 0).compareTo(progressMap[b.id] ?? 0));
        }
        break;
    }
    
    return sorted;
  }

  Widget _buildSortSelector(BuildContext context, WidgetRef ref) {
    final selectedSort = ref.watch(selectedSortProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.sort,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<SortOption>(
              value: selectedSort,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: SortOption.values.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(option.icon, size: 16),
                      const SizedBox(width: 8),
                      Text(option.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(selectedSortProvider.notifier).state = value;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => AddEditGoalBottomSheet(
        onSave: (goal) {
          ref.read(goalsProvider.notifier).addGoal(goal);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('새로운 목표가 추가되었습니다'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }
}
