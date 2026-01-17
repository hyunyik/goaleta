import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/widgets/goal_card.dart';
import 'package:goaleta/widgets/add_edit_goal_sheet.dart';
import 'package:goaleta/models/goal.dart';
import 'package:goaleta/screens/archives_screen.dart';
import 'package:goaleta/screens/settings_screen.dart';
import 'package:goaleta/utils/eta_calculator.dart';
import 'package:goaleta/services/onboarding_service.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:math';

// Provider for selected category filter
final selectedCategoryProvider = StateProvider<GoalCategory?>((ref) => null);

// Sort options
enum SortOption {
  createdDesc('생성일 (최신순)', Icons.access_time),
  createdAsc('생성일 (오래된순)', Icons.history),
  progressDesc('진행률 (높은순)', Icons.trending_up),
  progressAsc('진행률 (낮은순)', Icons.trending_down),
  deadlineAsc('마감일 (빠른순)', Icons.event),
  overdueDesc('초과일 (많은순)', Icons.warning_amber);

  final String label;
  final IconData icon;
  const SortOption(this.label, this.icon);
}

// Provider for selected sort option
final selectedSortProvider = StateProvider<SortOption>((ref) => SortOption.createdDesc);

// Wrapper widget with ShowCaseWidget
class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Showcase keys for each button
  final GlobalKey _addGoalKey = GlobalKey();
  final GlobalKey _trophiesKey = GlobalKey();
  final GlobalKey _archivesKey = GlobalKey();
  final GlobalKey _alarmKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _categoryFilterKey = GlobalKey();
  final GlobalKey _sortKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkAndStartTour();
  }
  
  void _checkAndStartTour() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasSeenTour = await OnboardingService.hasSeenHomeTour();
      if (!hasSeenTour && mounted) {
        _startShowCase();
      }
    });
  }

  void _startShowCase() {
    final goalsAsyncValue = ref.read(goalsProvider);
    final activeGoals = goalsAsyncValue.maybeWhen(
      data: (goals) => goals.where((g) => !g.isArchived).toList(),
      orElse: () => <Goal>[],
    );
    
    // Build the showcase list based on what's visible
    final showcaseKeys = <GlobalKey>[
      _addGoalKey,
      _trophiesKey,
      _archivesKey,
      _alarmKey,
      _settingsKey,
      // Only show category/sort if there are goals
      if (activeGoals.isNotEmpty) ...[
        _categoryFilterKey,
        _sortKey,
      ],
    ];
    
    ShowCaseWidget.of(context).startShowCase(showcaseKeys);
    // Mark tour as completed when it finishes
    OnboardingService.setHomeTourCompleted();
  }

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
  Widget build(BuildContext context) {
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
                        Showcase(
                          key: _trophiesKey,
                          description: '이번 달과 올해 달성한 목표의 개수를 보여줍니다. 목표를 완료하면 트로피가 늘어나요!',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Archives chip button
                        Showcase(
                          key: _archivesKey,
                          description: '달성한 목표들을 확인할 수 있습니다. 이번 달과 올해 달성한 목표 개수를 볼 수 있어요.',
                          child: InkWell(
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
                        ),
                        const SizedBox(width: 4),
                        // Alarm chip button
                        Showcase(
                          key: _alarmKey,
                          description: '매일 알림을 받아 목표를 잊지 않고 꾸준히 실천할 수 있어요. 탭해서 켜고 끌 수 있습니다.',
                          child: InkWell(
                            onTap: () async {
                              // If no alarm time set, open settings
                              if (alarmTime == null) {
                                final shouldRestartTour = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsScreen(),
                                  ),
                                );
                                if (shouldRestartTour == true && mounted) {
                                  // Small delay to ensure UI is ready
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  if (mounted) {
                                    _startShowCase();
                                  }
                                }
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
                        ),
                        const SizedBox(width: 4),
                        // More chip button
                        Showcase(
                          key: _settingsKey,
                          description: '앱 설정, 알림 시간 변경, 데이터 백업 및 복원 등을 할 수 있습니다.',
                          child: InkWell(
                            onTap: () async {
                              final shouldRestartTour = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                              if (shouldRestartTour == true && mounted) {
                                // Small delay to ensure UI is ready
                                await Future.delayed(const Duration(milliseconds: 300));
                                if (mounted) {
                                  _startShowCase();
                                }
                              }
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
              width: 70,
              height: 70,
              margin: const EdgeInsets.only(right: 8),
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
              Showcase(
                key: _categoryFilterKey,
                description: '카테고리별로 목표를 필터링할 수 있습니다. 건강, 학습, 취미, 업무 등 카테고리를 선택하세요.',
                child: _buildCategoryChips(context, ref, activeGoals),
              ),
              // Sort selector
              Showcase(
                key: _sortKey,
                description: '목표를 생성일, 진행률, 마감일 등 다양한 기준으로 정렬할 수 있습니다.',
                child: _buildSortSelector(context, ref),
              ),
              // Goal list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 80, // Add extra padding to prevent FAB from blocking content
                  ),
                  itemCount: filteredGoals.length,
                  itemBuilder: (context, index) {
                    final goal = filteredGoals[index];
                    return GoalCard(
                      key: ValueKey(goal.id),
                      goal: goal,
                      onEdit: () => _showEditGoalSheet(context, ref, goal),
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
      floatingActionButton: Showcase(
        key: _addGoalKey,
        title: '새 목표 추가',
        description: '여기를 눌러 새로운 목표를 추가할 수 있습니다. 목표 이름, 목표량, 현재까지 완료한 양, 마감일 등을 설정하세요.',
        targetShapeBorder: const CircleBorder(),
        child: FloatingActionButton.extended(
          heroTag: 'main_fab',
          onPressed: () {
            _showAddGoalSheet(context, ref);
          },
          backgroundColor: Colors.purpleAccent,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            '새 목표',
            style: TextStyle(color: Colors.white),
          ),
        ),
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
      case SortOption.deadlineAsc:
        // Sort by deadline (earliest first), goals without deadline at the end
        sorted.sort((a, b) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1; // a goes to back
          if (b.deadline == null) return -1; // b goes to back
          return a.deadline!.compareTo(b.deadline!);
        });
        break;
      case SortOption.overdueDesc:
        // Sort by overdue days (most overdue first), goals without deadline at the end
        // Calculate ETA for each goal to determine overdue days
        final overdueMap = <String, int>{};
        for (final goal in goals) {
          if (goal.deadline == null) {
            overdueMap[goal.id] = -999999; // Send to back
          } else {
            final logsAsync = ref.read(logsProvider(goal.id));
            final completedAsync = ref.read(completedAmountProvider(goal.id));
            
            final logs = logsAsync.maybeWhen(
              data: (l) => l,
              orElse: () => [],
            );
            final completed = completedAsync.maybeWhen(
              data: (amount) => amount,
              orElse: () => 0.0,
            );
            
            final etaData = ETACalculator.calculateSimpleAverageETA(
              cumulativeAmount: completed,
              totalAmount: goal.totalAmount,
              startDate: goal.startDate,
              logs: logs.cast<LogEntry>(),
              excludeWeekends: goal.excludeWeekends,
              startingAmount: goal.startingAmount,
            );
            
            if (etaData != null) {
              final estimatedDate = etaData['estimatedDate'] as DateTime;
              final overdueDays = estimatedDate.difference(goal.deadline!).inDays;
              overdueMap[goal.id] = overdueDays;
            } else {
              // No logs yet, can't calculate overdue
              overdueMap[goal.id] = -999998; // Send to back but before null deadlines
            }
          }
        }
        
        sorted.sort((a, b) => (overdueMap[b.id] ?? 0).compareTo(overdueMap[a.id] ?? 0));
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

  void _showEditGoalSheet(BuildContext context, WidgetRef ref, Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => AddEditGoalBottomSheet(
        existingGoal: goal,
        onSave: (updatedGoal) {
          ref.read(goalsProvider.notifier).updateGoal(updatedGoal);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('목표가 수정되었습니다'),
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

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => ShowCaseWidget(
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
      ),
    );
  }
}
