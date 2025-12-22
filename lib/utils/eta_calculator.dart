import 'package:goaleta/models/goal.dart';

class ETACalculator {
  /// 단순 평균 기반 ETA 계산
  /// 
  /// [completedAmount]: 현재까지 완료된 양
  /// [totalAmount]: 목표 총량
  /// [startDate]: 목표 시작일
  /// [logs]: 기록 리스트
  /// 
  /// 반환: {'remainingDays': 남은 일수, 'estimatedDate': 예상 완료일}
  static Map<String, dynamic> calculateSimpleAverageETA({
    required double completedAmount,
    required double totalAmount,
    required DateTime startDate,
    required List<LogEntry> logs,
    bool excludeWeekends = false,
  }) {
    if (completedAmount >= totalAmount) {
      return {
        'remainingDays': 0,
        'estimatedDate': DateTime.now(),
      };
    }

    final remaining = totalAmount - completedAmount;

    // 경과한 날수 계산 (주말 제외 옵션)
    int elapsedDays = _getElapsedDays(startDate, excludeWeekends);
    if (elapsedDays == 0) elapsedDays = 1; // 최소 1일

    // 일일 평균 계산
    double dailyAverage = completedAmount / elapsedDays;
    if (dailyAverage <= 0) dailyAverage = 0.1; // 최소 0.1

    // 남은 기간 계산
    int remainingDays = (remaining / dailyAverage).ceil();
    
    // 예상 완료일
    DateTime estimatedDate = _addDays(DateTime.now(), remainingDays, excludeWeekends);

    return {
      'remainingDays': remainingDays,
      'estimatedDate': estimatedDate,
      'dailyAverage': dailyAverage,
    };
  }

  /// 최근 가중 평균 기반 ETA 계산 (최근 14일 기준)
  static Map<String, dynamic> calculateWeightedAverageETA({
    required double completedAmount,
    required double totalAmount,
    required DateTime startDate,
    required List<LogEntry> logs,
    bool excludeWeekends = false,
    int recentDays = 14,
  }) {
    if (completedAmount >= totalAmount) {
      return {
        'remainingDays': 0,
        'estimatedDate': DateTime.now(),
      };
    }

    final remaining = totalAmount - completedAmount;

    // 최근 N일 동안의 기록 필터링
    final now = DateTime.now();
    final cutoffDate = DateTime(
      now.year,
      now.month,
      now.day - recentDays,
    );

    final recentLogs = logs
        .where((log) =>
            log.logDate.isAfter(cutoffDate) ||
            log.logDate.isAtSameMomentAs(cutoffDate))
        .toList();

    double dailyAverage;

    if (recentLogs.isEmpty) {
      // 최근 기록이 없으면 단순 평균 사용
      int elapsedDays = _getElapsedDays(startDate, excludeWeekends);
      if (elapsedDays == 0) elapsedDays = 1;
      dailyAverage = completedAmount / elapsedDays;
      if (dailyAverage <= 0) dailyAverage = 0.1;
    } else {
      // 최근 기록들의 평균 계산
      final totalRecent = recentLogs.fold<double>(
        0,
        (sum, log) => sum + log.amount,
      );
      dailyAverage = totalRecent / recentLogs.length;
      if (dailyAverage <= 0) dailyAverage = 0.1;
    }

    // 남은 기간 계산
    int remainingDays = (remaining / dailyAverage).ceil();

    // 예상 완료일
    DateTime estimatedDate = _addDays(DateTime.now(), remainingDays, excludeWeekends);

    return {
      'remainingDays': remainingDays,
      'estimatedDate': estimatedDate,
      'dailyAverage': dailyAverage,
    };
  }

  /// 경과한 날수 계산
  static int _getElapsedDays(DateTime startDate, bool excludeWeekends) {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;

    if (!excludeWeekends) {
      return now.difference(startDate).inDays + 1;
    }

    // 주말 제외 계산
    int days = 0;
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(now.year, now.month, now.day);

    while (current.isBefore(today) || current.isAtSameMomentAs(today)) {
      if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  /// N일 뒤의 날짜 계산
  static DateTime _addDays(DateTime date, int days, bool excludeWeekends) {
    if (!excludeWeekends) {
      return date.add(Duration(days: days));
    }

    DateTime result = date;
    int addedDays = 0;

    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday && result.weekday != DateTime.sunday) {
        addedDays++;
      }
    }

    return result;
  }

  /// 기록 일별로 그룹화
  static Map<DateTime, double> groupLogsByDate(List<LogEntry> logs) {
    final grouped = <DateTime, double>{};
    for (final log in logs) {
      final date = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      grouped[date] = (grouped[date] ?? 0) + log.amount;
    }
    return grouped;
  }

  /// 최근 N일간의 일별 기록 데이터
  static List<double> getRecentDaysData({
    required List<LogEntry> logs,
    required int days,
  }) {
    final grouped = groupLogsByDate(logs);
    final result = <double>[];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day - i,
      );
      result.add(grouped[date] ?? 0);
    }

    return result;
  }
}
