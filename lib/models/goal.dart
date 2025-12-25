import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

enum GoalCategory {
  reading,
  study,
  fitness,
  writing,
  practice,
  custom;

  String get displayName {
    switch (this) {
      case GoalCategory.reading:
        return '읽기';
      case GoalCategory.study:
        return '공부';
      case GoalCategory.fitness:
        return '운동';
      case GoalCategory.writing:
        return '쓰기';
      case GoalCategory.practice:
        return '연습';
      case GoalCategory.custom:
        return '기타';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalCategory.reading:
        return Icons.menu_book;
      case GoalCategory.study:
        return Icons.school;
      case GoalCategory.fitness:
        return Icons.fitness_center;
      case GoalCategory.writing:
        return Icons.edit_note;
      case GoalCategory.practice:
        return Icons.piano;
      case GoalCategory.custom:
        return Icons.more_horiz;
    }
  }

  Color getColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (this) {
      case GoalCategory.reading:
        return Colors.blue;
      case GoalCategory.study:
        return Colors.purple;
      case GoalCategory.fitness:
        return Colors.orange;
      case GoalCategory.writing:
        return Colors.green;
      case GoalCategory.practice:
        return Colors.pink;
      case GoalCategory.custom:
        return colorScheme.primary;
    }
  }
}

class Goal {
  final String id;
  final String title;
  final String unit; // 페이지, 분, 개, 세트 등
  final double totalAmount;
  final DateTime startDate;
  final bool excludeWeekends;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final GoalCategory category;

  Goal({
    String? id,
    required this.title,
    required this.unit,
    required this.totalAmount,
    DateTime? startDate,
    this.excludeWeekends = false,
    DateTime? createdAt,
    this.isCompleted = false,
    this.completedAt,
    this.category = GoalCategory.custom,
  })  : id = id ?? const Uuid().v4(),
        startDate = startDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  double getProgressPercentage(double completedAmount) {
    if (totalAmount <= 0) return 0;
    return (completedAmount / totalAmount * 100).clamp(0, 100);
  }

  double getRemainingAmount(double completedAmount) {
    return (totalAmount - completedAmount).clamp(0, double.infinity);
  }

  // Goal 객체를 복사본으로 만들기
  Goal copyWith({
    String? id,
    String? title,
    String? unit,
    double? totalAmount,
    DateTime? startDate,
    bool? excludeWeekends,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
    GoalCategory? category,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      unit: unit ?? this.unit,
      totalAmount: totalAmount ?? this.totalAmount,
      startDate: startDate ?? this.startDate,
      excludeWeekends: excludeWeekends ?? this.excludeWeekends,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'unit': unit,
      'totalAmount': totalAmount,
      'startDate': startDate.toIso8601String(),
      'excludeWeekends': excludeWeekends,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'category': category.name,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      unit: json['unit'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      excludeWeekends: json['excludeWeekends'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      category: GoalCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GoalCategory.custom,
      ),
    );
  }
}

class LogEntry {
  final String id;
  final String goalId;
  final double amount;
  final DateTime logDate;
  final DateTime createdAt;
  final String? note;

  LogEntry({
    String? id,
    required this.goalId,
    required this.amount,
    DateTime? logDate,
    DateTime? createdAt,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        logDate = logDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  LogEntry copyWith({
    String? id,
    String? goalId,
    double? amount,
    DateTime? logDate,
    DateTime? createdAt,
    String? note,
  }) {
    return LogEntry(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      logDate: logDate ?? this.logDate,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'amount': amount,
      'logDate': logDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      goalId: json['goalId'],
      amount: (json['amount'] as num).toDouble(),
      logDate: DateTime.parse(json['logDate']),
      createdAt: DateTime.parse(json['createdAt']),
      note: json['note'],
    );
  }
}
