import 'package:flutter/material.dart';
import 'package:goaleta/models/goal.dart';
import 'package:intl/intl.dart';

class AddLogBottomSheet extends StatefulWidget {
  final String goalId;
  final String unit;
  final LogEntry? existingLog;
  final Function(LogEntry) onSave;

  const AddLogBottomSheet({
    required this.goalId,
    required this.unit,
    this.existingLog,
    required this.onSave,
    Key? key,
  }) : super(key: key);

  @override
  State<AddLogBottomSheet> createState() => _AddLogBottomSheetState();
}

class _AddLogBottomSheetState extends State<AddLogBottomSheet> {
  late TextEditingController amountController;
  late TextEditingController noteController;
  late DateTime logDate;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: widget.existingLog?.amount.toString() ?? '',
    );
    noteController = TextEditingController(text: widget.existingLog?.note ?? '');
    logDate = widget.existingLog?.logDate ?? DateTime.now();
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (amountController.text.isEmpty) {
      _showErrorSnackBar('값을 입력해주세요');
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount < 0) {
      _showErrorSnackBar('유효한 값을 입력해주세요');
      return;
    }

    final log = (widget.existingLog ??
            LogEntry(goalId: widget.goalId, amount: 0))
        .copyWith(
      amount: amount,
      logDate: logDate,
      note: noteController.text.isEmpty ? null : noteController.text,
    );

    Navigator.of(context).pop();
    widget.onSave(log);
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
      initialDate: logDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        logDate = picked;
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
                  widget.existingLog == null ? '기록 추가' : '기록 수정',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 값 입력
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '값',
                hintText: '예: 50',
                suffixText: widget.unit,
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 날짜
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('날짜'),
              subtitle: Text(dateFormatter.format(logDate)),
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
            const SizedBox(height: 20),

            // 메모 (선택사항)
            TextField(
              controller: noteController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                labelText: '메모 (선택)',
                hintText: '예: 집중이 잘 됐음',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
