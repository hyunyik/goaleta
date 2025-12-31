import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goaleta/models/goal.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 로컬 저장소 (Hive 사용)
class LocalStorage {
  static const String goalsBoxName = 'goals';
  static const String logsBoxName = 'logs';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(goalsBoxName);
    await Hive.openBox<Map>(logsBoxName);
  }

  static Box<Map> get _goalsBox => Hive.box<Map>(goalsBoxName);
  static Box<Map> get _logsBox => Hive.box<Map>(logsBoxName);

  static Future<void> saveGoal(Goal goal) async {
    await _goalsBox.put(goal.id, goal.toJson());
  }

  static Future<void> deleteGoal(String goalId) async {
    await _goalsBox.delete(goalId);
    await _logsBox.delete(goalId);
  }

  static Future<List<Goal>> getAllGoals() async {
    final goals = <Goal>[];
    for (var entry in _goalsBox.values) {
      try {
        goals.add(Goal.fromJson(Map<String, dynamic>.from(entry)));
      } catch (e) {
        print('Error loading goal: $e');
      }
    }
    return goals;
  }

  static Future<Goal?> getGoal(String goalId) async {
    final data = _goalsBox.get(goalId);
    if (data == null) return null;
    return Goal.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<void> saveLogEntry(LogEntry entry) async {
    final logsData = _logsBox.get(entry.goalId);
    final logs = logsData != null 
        ? (logsData as Map).values.map((e) => LogEntry.fromJson(Map<String, dynamic>.from(e))).toList()
        : <LogEntry>[];
    
    final index = logs.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      logs[index] = entry;
    } else {
      logs.add(entry);
    }
    
    final logsMap = {for (var log in logs) log.id: log.toJson()};
    await _logsBox.put(entry.goalId, logsMap);
  }

  static Future<void> deleteLogEntry(String goalId, String logId) async {
    final logsData = _logsBox.get(goalId);
    if (logsData != null) {
      final logsMap = Map<String, dynamic>.from(logsData);
      logsMap.remove(logId);
      await _logsBox.put(goalId, logsMap);
    }
  }

  static Future<List<LogEntry>> getLogsByGoal(String goalId) async {
    final logsData = _logsBox.get(goalId);
    if (logsData == null) return [];
    
    final logs = <LogEntry>[];
    for (var entry in (logsData as Map).values) {
      try {
        logs.add(LogEntry.fromJson(Map<String, dynamic>.from(entry)));
      } catch (e) {
        print('Error loading log: $e');
      }
    }
    return logs;
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
