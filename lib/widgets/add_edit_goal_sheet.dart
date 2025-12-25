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
  late DateTime selectedDate;
  late bool excludeWeekends;
  late GoalCategory selectedCategory;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existingGoal?.title ?? '');
    unitController = TextEditingController(text: widget.existingGoal?.unit ?? '');
    totalAmountController = TextEditingController(
      text: widget.existingGoal?.totalAmount.toString() ?? '',
    );
    selectedDate = widget.existingGoal?.startDate ?? DateTime.now();
    excludeWeekends = widget.existingGoal?.excludeWeekends ?? false;
    selectedCategory = widget.existingGoal?.category ?? GoalCategory.custom;
  }

  @override
  void dispose() {
    titleController.dispose();
    unitController.dispose();
    totalAmountController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (titleController.text.isEmpty ||
        unitController.text.isEmpty ||
        totalAmountController.text.isEmpty) {
      _showErrorSnackBar('모든 필드를 입력해주세요');
      return;
    }

    final totalAmount = double.tryParse(totalAmountController.text);
    if (totalAmount == null || totalAmount <= 0) {
      _showErrorSnackBar('유효한 총량을 입력해주세요');
      return;
    }

    final goal = (widget.existingGoal ?? Goal(
      title: '',
      unit: '',
      totalAmount: 0,
    )).copyWith(
      title: titleController.text.trim(),
      unit: unitController.text.trim(),
      totalAmount: totalAmount,
      startDate: selectedDate,
      excludeWeekends: excludeWeekends,
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

            // 단위와 총량을 같은 줄에 배치
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: unitController,
                    decoration: InputDecoration(
                      labelText: '단위',
                      hintText: '페이지, 분 등',
                      prefixIcon: const Icon(Icons.straighten),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
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
              ],
            ),
            const SizedBox(height: 20),

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
