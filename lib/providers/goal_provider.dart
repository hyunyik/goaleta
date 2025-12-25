import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goaleta/models/goal.dart';

/// 로컬 저장소 시뮬레이션 (실제로는 Hive 또는 SharedPreferences 사용)
class LocalStorage {
  static final Map<String, Goal> _goals = {};
  static final Map<String, List<LogEntry>> _logs = {};

  static Future<void> saveGoal(Goal goal) async {
    _goals[goal.id] = goal;
  }

  static Future<void> deleteGoal(String goalId) async {
    _goals.remove(goalId);
    _logs.remove(goalId);
  }

  static Future<List<Goal>> getAllGoals() async {
    return _goals.values.toList();
  }

  static Future<Goal?> getGoal(String goalId) async {
    return _goals[goalId];
  }

  static Future<void> saveLogEntry(LogEntry entry) async {
    if (!_logs.containsKey(entry.goalId)) {
      _logs[entry.goalId] = [];
    }
    final index = _logs[entry.goalId]!.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      _logs[entry.goalId]![index] = entry;
    } else {
      _logs[entry.goalId]!.add(entry);
    }
  }

  static Future<void> deleteLogEntry(String goalId, String logId) async {
    if (_logs.containsKey(goalId)) {
      _logs[goalId]!.removeWhere((e) => e.id == logId);
    }
  }

  static Future<List<LogEntry>> getLogsByGoal(String goalId) async {
    return _logs[goalId] ?? [];
  }
}

/// Goal 목록 제공자
final goalsProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<List<Goal>>>((ref) {
  return GoalNotifier();
});

class GoalNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  GoalNotifier() : super(const AsyncValue.loading()) {
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await LocalStorage.getAllGoals();
      goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(goals);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addGoal(Goal goal) async {
    try {
      await LocalStorage.saveGoal(goal);
      await _loadGoals();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await LocalStorage.saveGoal(goal);
      await _loadGoals();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await LocalStorage.deleteGoal(goalId);
      await _loadGoals();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// 특정 Goal 상세 정보 제공자
final goalDetailProvider =
    FutureProvider.family<Goal?, String>((ref, goalId) async {
  final goalsAsync = ref.watch(goalsProvider);
  final goals = goalsAsync.maybeWhen(
    data: (data) => data,
    orElse: () => <Goal>[],
  );
  try {
    return goals.firstWhere((g) => g.id == goalId);
  } catch (e) {
    return Goal(
      id: goalId,
      title: 'Not Found',
      unit: '',
      totalAmount: 0,
    );
  }
});

/// 특정 Goal의 로그 목록 제공자
final logsProvider = FutureProvider.family<List<LogEntry>, String>((ref, goalId) async {
  return LocalStorage.getLogsByGoal(goalId);
});

class LogNotifier extends StateNotifier<AsyncValue<List<LogEntry>>> {
  final String goalId;

  LogNotifier(this.goalId) : super(const AsyncValue.loading()) {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await LocalStorage.getLogsByGoal(goalId);
      logs.sort((a, b) => b.logDate.compareTo(a.logDate));
      state = AsyncValue.data(logs);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addLog(LogEntry entry) async {
    try {
      await LocalStorage.saveLogEntry(entry);
      await _loadLogs();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateLog(LogEntry entry) async {
    try {
      await LocalStorage.saveLogEntry(entry);
      await _loadLogs();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteLog(String logId) async {
    try {
      await LocalStorage.deleteLogEntry(goalId, logId);
      await _loadLogs();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// 특정 Goal의 로그 상태 제공자
final logNotifierProvider =
    StateNotifierProvider.family<LogNotifier, AsyncValue<List<LogEntry>>, String>(
        (ref, goalId) {
  return LogNotifier(goalId);
});

/// 특정 Goal의 완료된 총량 계산
final completedAmountProvider =
    FutureProvider.family<double, String>((ref, goalId) async {
  final logs = await ref.watch(logsProvider(goalId).future);
  return logs.fold<double>(0, (sum, log) => sum + log.amount);
});
