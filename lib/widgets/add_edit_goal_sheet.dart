import 'package:flutter/material.dart';
import 'package:goaleta/models/goal.dart';
import 'package:intl/intl.dart';

class AddEditGoalBottomSheet extends StatefulWidget {
  final Goal? existingGoal;
  final Function(Goal) onSave;

  const AddEditGoalBottomSheet({
    this.existingGoal,
    required this.onSave,
    Key? key,
  }) : super(key: key);

  @override
  State<AddEditGoalBottomSheet> createState() => _AddEditGoalBottomSheetState();
}

class _AddEditGoalBottomSheetState extends State<AddEditGoalBottomSheet> {
  late TextEditingController titleController;
  late TextEditingController unitController;
  late TextEditingController totalAmountController;
  late TextEditingController startingAmountController;
  late DateTime selectedDate;
  late bool excludeWeekends;
  late GoalCategory selectedCategory;
  String? selectedUnit; // null means custom input
  DateTime? selectedDeadline;

  // Unit suggestions based on category
  List<String> get suggestedUnits {
    switch (selectedCategory) {
      case GoalCategory.reading:
        return ['페이지', '권', '챕터'];
      case GoalCategory.study:
        return ['시간', '분', '문제', '강의'];
      case GoalCategory.fitness:
        return ['회', '분', 'km', '세트'];
      case GoalCategory.writing:
        return ['단어', '페이지', '글'];
      case GoalCategory.practice:
        return ['시간', '분', '회'];
      case GoalCategory.custom:
        return ['개', '회', '시간'];
    }
  }

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existingGoal?.title ?? '');
    unitController = TextEditingController(text: widget.existingGoal?.unit ?? '');
    totalAmountController = TextEditingController(
      text: widget.existingGoal?.totalAmount.toString() ?? '',
    );
    startingAmountController = TextEditingController(
      text: widget.existingGoal?.startingAmount.toString() ?? '0',
    );
    selectedDate = widget.existingGoal?.startDate ?? DateTime.now();
    excludeWeekends = widget.existingGoal?.excludeWeekends ?? false;
    selectedCategory = widget.existingGoal?.category ?? GoalCategory.custom;
    selectedDeadline = widget.existingGoal?.deadline;
    
    // Initialize selectedUnit based on existing goal
    if (widget.existingGoal?.unit != null) {
      final unit = widget.existingGoal!.unit;
      if (suggestedUnits.contains(unit)) {
        selectedUnit = unit;
      } else {
        selectedUnit = null; // Will show as custom
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    unitController.dispose();
    totalAmountController.dispose();
    startingAmountController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // Get unit from either selected chip or custom input
    final unit = selectedUnit ?? unitController.text.trim();
    
    if (titleController.text.isEmpty ||
        unit.isEmpty ||
        totalAmountController.text.isEmpty) {
      _showErrorSnackBar('모든 필드를 입력해주세요');
      return;
    }

    final totalAmount = double.tryParse(totalAmountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      _showErrorSnackBar('유효한 총량을 입력해주세요');
      return;
    }

    final startingAmount = double.tryParse(startingAmountController.text) ?? 0;
    if (startingAmount < 0) {
      _showErrorSnackBar('시작값은 0 이상이어야 합니다');
      return;
    }

    final goal = (widget.existingGoal ?? Goal(
      title: '',
      unit: '',
      totalAmount: 0,
    )).copyWith(
      title: titleController.text.trim(),
      unit: unit,
      totalAmount: totalAmount,
      startingAmount: startingAmount,
      startDate: selectedDate,
      excludeWeekends: excludeWeekends,
      deadline: selectedDeadline,
      category: selectedCategory,
    );

    Navigator.of(context).pop();
    widget.onSave(goal);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showCustomUnitDialog() async {
    final controller = TextEditingController(text: unitController.text);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 정의 단위'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '단위를 입력하세요',
            hintText: '예: 페이지, 분, 회',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        selectedUnit = null; // Mark as custom
        unitController.text = result;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDeadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy.MM.dd');

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingGoal == null ? '새 목표 만들기' : '목표 수정',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 제목
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: '목표 제목',
                hintText: '예: 책 읽기',
                prefixIcon: const Icon(Icons.book),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 카테고리 선택
            Text(
              '카테고리',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GoalCategory.values.map((category) {
                final isSelected = selectedCategory == category;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 16,
                        color: isSelected
                            ? category.getColor(context)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(category.displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  selectedColor: category.getColor(context).withOpacity(0.2),
                  side: BorderSide(
                    color: isSelected
                        ? category.getColor(context)
                        : Theme.of(context).colorScheme.outline,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 단위 선택 (Chips)
            Text(
              '단위',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...suggestedUnits.map((unit) {
                  final isSelected = selectedUnit == unit;
                  return ChoiceChip(
                    label: Text(unit),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedUnit = selected ? unit : null;
                      });
                    },
                  );
                }),
                // "기타" chip for custom input
                ChoiceChip(
                  label: const Text('기타'),
                  selected: selectedUnit == null && unitController.text.isNotEmpty,
                  onSelected: (selected) {
                    if (selected) {
                      _showCustomUnitDialog();
                    }
                  },
                ),
              ],
            ),
            if (selectedUnit == null && unitController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '사용자 정의: ${unitController.text}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showCustomUnitDialog,
                      child: const Text('수정'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // 총량과 시작값을 같은 줄에 배치
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: totalAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '총량',
                      hintText: '예: 500',
                      prefixIcon: const Icon(Icons.track_changes),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: startingAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '시작값',
                      hintText: '기본: 0',
                      prefixIcon: const Icon(Icons.start),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 마감일 (선택적)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('마감일 (선택)'),
              subtitle: Text(
                selectedDeadline != null
                    ? dateFormatter.format(selectedDeadline!)
                    : '설정 안 함',
              ),
              leading: Icon(
                Icons.event,
                color: Theme.of(context).colorScheme.primary,
              ),
              trailing: selectedDeadline != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          selectedDeadline = null;
                        });
                      },
                    )
                  : null,
              onTap: () => _selectDeadline(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 
            // 시작일
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('시작일'),
              subtitle: Text(dateFormatter.format(selectedDate)),
              leading: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () => _selectDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 주말 제외 옵션
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('주말 제외하기'),
                subtitle: const Text('ETA 계산에서 토일을 제외합니다'),
                value: excludeWeekends,
                onChanged: (value) {
                  setState(() {
                    excludeWeekends = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
