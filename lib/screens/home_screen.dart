import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/widgets/goal_card.dart';
import 'package:goaleta/widgets/add_edit_goal_sheet.dart';
import 'package:goaleta/models/goal.dart';
import 'dart:math';

// Provider for selected category filter
final selectedCategoryProvider = StateProvider<GoalCategory?>((ref) => null);

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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: goalsAsyncValue.when(
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
          if (goals.isEmpty) {
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
          final filteredGoals = selectedCategory == null
              ? goals
              : goals.where((g) => g.category == selectedCategory).toList();

          return Column(
            children: [
              // Category filter chips
              _buildCategoryChips(context, ref, goals),
              // Reorderable goal list
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredGoals.length,
                  onReorder: (oldIndex, newIndex) {
                    _onReorder(ref, goals, filteredGoals, oldIndex, newIndex);
                  },
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

  void _onReorder(WidgetRef ref, List<Goal> allGoals, List<Goal> filteredGoals, int oldIndex, int newIndex) {
    // Adjust newIndex for list behavior
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Reorder within filtered list
    final movedGoal = filteredGoals[oldIndex];
    filteredGoals.removeAt(oldIndex);
    filteredGoals.insert(newIndex, movedGoal);

    // Update all goals order by maintaining filtered goals' new positions
    // and keeping other goals in their relative positions
    // For simplicity, we'll just update the createdAt timestamps to maintain order
    // This is a simplified approach - in a real app, you might want a dedicated order field
    
    final now = DateTime.now();
    for (int i = 0; i < filteredGoals.length; i++) {
      final updatedGoal = filteredGoals[i].copyWith(
        createdAt: now.subtract(Duration(minutes: filteredGoals.length - i)),
      );
      ref.read(goalsProvider.notifier).updateGoal(updatedGoal);
    }
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
