import 'package:flutter/material.dart';
import 'package:goaleta/models/goal.dart';
import 'package:goaleta/widgets/custom_date_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:goaleta/services/onboarding_service.dart';

class AddLogBottomSheet extends ConsumerStatefulWidget {
  final String goalId;
  final String unit;
  final LogEntry? existingLog;
  final Function(LogEntry) onSave;
  final double? previousCumulativeTotal;
  final DateTime goalStartDate;
  final double startingAmount;
  final DateTime? latestLogDate;
  final List<DateTime> existingLogDates;
  final Goal goal;
  final bool isFirstRecordOfFirstGoal;

  const AddLogBottomSheet({
    required this.goalId,
    required this.unit,
    this.existingLog,
    required this.onSave,
    this.previousCumulativeTotal,
    required this.goalStartDate,
    this.startingAmount = 0,
    this.latestLogDate,
    this.existingLogDates = const [],
    required this.goal,
    this.isFirstRecordOfFirstGoal = false,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<AddLogBottomSheet> createState() => _AddLogBottomSheetState();
}

class _AddLogBottomSheetState extends ConsumerState<AddLogBottomSheet> {
  late TextEditingController amountController;
  late TextEditingController noteController;
  late DateTime logDate;
  bool isAccumulativeMode = false; // true: 누적, false: 일일
  
  // Validation error states
  bool _amountError = false;
  String? _amountErrorMessage;
  
  // Showcase keys for tour
  final GlobalKey _modeKey = GlobalKey();
  final GlobalKey _amountKey = GlobalKey();
  final GlobalKey _dateKey = GlobalKey();
  final GlobalKey _noteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: widget.existingLog?.amount.toString() ?? '',
    );
    noteController =
        TextEditingController(text: widget.existingLog?.note ?? '');
    logDate = widget.existingLog?.logDate ?? DateTime.now();
    
    // Check and start tour for first record of first goal
    if (widget.existingLog == null && widget.isFirstRecordOfFirstGoal) {
      _checkAndStartTour();
    }
  }
  
  void _checkAndStartTour() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasSeenTour = await OnboardingService.hasSeenLogFormTour();
      if (!hasSeenTour && mounted) {
        _startShowCase();
      }
    });
  }

  void _startShowCase() {
    final showcaseKeys = <GlobalKey>[
      _modeKey,
      _amountKey,
      _dateKey,
      _noteKey,
    ];
    
    ShowCaseWidget.of(context).startShowCase(showcaseKeys);
    OnboardingService.setLogFormTourCompleted();
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // Reset error states
    setState(() {
      _amountError = false;
      _amountErrorMessage = null;
    });
    
    bool hasError = false;
    
    // Validate amount
    if (amountController.text.isEmpty) {
      setState(() {
        _amountError = true;
        _amountErrorMessage = '값을 입력해주세요';
      });
      hasError = true;
    } else {
      final inputValue = double.tryParse(amountController.text);
      if (inputValue == null || inputValue < 0) {
        setState(() {
          _amountError = true;
          _amountErrorMessage = '0 이상의 값을 입력해주세요';
        });
        hasError = true;
      }
    }
    
    if (hasError) {
      _showErrorSnackBar('필수 항목을 모두 입력해주세요');
      return;
    }
    
    final inputValue = double.tryParse(amountController.text)!;

    double finalAmount;
    if (isAccumulativeMode) {
      // 누적 모드: (입력값 - 시작값) - 이전 누적값 계산
      final totalCumulative =
          widget.startingAmount + (widget.previousCumulativeTotal ?? 0);
      finalAmount = inputValue - totalCumulative;

      if (inputValue < totalCumulative) {
        _showErrorSnackBar(
            '누적값은 현재값(${totalCumulative.toStringAsFixed(0)})보다 커야 합니다');
        return;
      }
    } else {
      // 일일 모드: 입력한 값 그대로 사용
      finalAmount = inputValue;
    }

    final log =
        (widget.existingLog ?? LogEntry(goalId: widget.goalId, amount: 0))
            .copyWith(
      amount: finalAmount,
      logDate: logDate,
      note: noteController.text.isEmpty ? null : noteController.text,
    );

    // Just save and pop - let parent handle completion checking
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
    // In cumulative mode, restrict to dates on or after the latest log
    final DateTime effectiveFirstDate;
    if (isAccumulativeMode && widget.latestLogDate != null) {
      effectiveFirstDate = widget.latestLogDate!;
    } else {
      effectiveFirstDate = widget.goalStartDate;
    }

    final picked = await showCustomDatePicker(
      context: context,
      initialDate:
          logDate.isBefore(effectiveFirstDate) ? effectiveFirstDate : logDate,
      firstDate: effectiveFirstDate,
      lastDate: DateTime.now(),
      startDate: widget.goalStartDate,
      datesWithRecords: widget.existingLogDates.toSet(),
    );
    if (picked != null) {
      setState(() {
        logDate = picked;
        // Disable cumulative mode if selected date is before latest log
        if (widget.latestLogDate != null &&
            picked.isBefore(widget.latestLogDate!)) {
          isAccumulativeMode = false;
          amountController.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy.MM.dd');

    return SafeArea(
      child: SingleChildScrollView(
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

            // 입력 모드 선택
            if (widget.existingLog == null) // 새 기록 추가시에만 표시
              Showcase(
                key: _modeKey,
                description: '기록 입력 방식을 선택하세요.\n• 일일: 오늘 달성한 양만 입력 (예: 오늘 50페이지 읽음)\n• 누적: 현재까지의 전체 누적값 입력 (예: 총 150페이지까지 읽음)',
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isAccumulativeMode = false;
                            amountController.clear();
                          });
                        },
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isAccumulativeMode
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.today,
                                color: !isAccumulativeMode
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '일일',
                                style: TextStyle(
                                  color: !isAccumulativeMode
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  fontWeight: !isAccumulativeMode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          // Disable if current date is before latest log
                          if (widget.latestLogDate != null &&
                              logDate.isBefore(widget.latestLogDate!)) {
                            _showErrorSnackBar(
                                '누적 모드는 최근 기록(${DateFormat('MM.dd').format(widget.latestLogDate!)}) 이후만 사용 가능합니다');
                            return;
                          }
                          setState(() {
                            isAccumulativeMode = true;
                            amountController.clear();
                          });
                        },
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        child: Opacity(
                          opacity: (widget.latestLogDate != null &&
                                  logDate.isBefore(widget.latestLogDate!))
                              ? 0.4
                              : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isAccumulativeMode
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: isAccumulativeMode
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '누적',
                                  style: TextStyle(
                                    color: isAccumulativeMode
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: isAccumulativeMode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.existingLog == null) const SizedBox(height: 20),

            // 값 입력
            Showcase(
              key: _amountKey,
              description: '달성한 양을 입력하세요.\n• 일일 모드: 오늘 한 양을 입력 (예: 50)\n• 누적 모드: 현재까지의 전체 누적값 입력 (예: 150)',
              child: TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isAccumulativeMode ? '누적값 *' : '값 *',
                  hintText: isAccumulativeMode
                      ? (widget.previousCumulativeTotal != null
                          ? '예: ${(widget.startingAmount + widget.previousCumulativeTotal! + 50).toStringAsFixed(0)} (현재: ${(widget.startingAmount + widget.previousCumulativeTotal!).toStringAsFixed(0)})'
                          : widget.startingAmount > 0
                              ? '예: ${(widget.startingAmount + 50).toStringAsFixed(0)} (시작: ${widget.startingAmount.toStringAsFixed(0)})'
                              : '예: 150')
                      : '예: 50',
                  suffixText: widget.unit,
                  prefixIcon: Icon(
                    isAccumulativeMode ? Icons.trending_up : Icons.edit_note,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _amountError ? _amountErrorMessage : null,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                  ),
                  helperText: _amountError ? null : (isAccumulativeMode ? '전체 누적값을 입력하세요' : '오늘 달성한 양을 입력하세요'),
                ),
                onChanged: (value) {
                  if (_amountError && value.isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount != null && amount >= 0) {
                      setState(() {
                        _amountError = false;
                        _amountErrorMessage = null;
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // 날짜
            Showcase(
              key: _dateKey,
              description: '기록의 날짜를 선택하세요. 목표 시작일부터 오늘까지 선택할 수 있습니다. 이미 기록이 있는 날은 달력에 표시됩니다.',
              child: ListTile(
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
            ),
            const SizedBox(height: 20),

            // 메모 (선택사항)
            Showcase(
              key: _noteKey,
              description: '오늘의 기록에 대한 메모를 남길 수 있습니다. 예: "집중이 잘 됐음", "힘들었지만 완료" 등',
              child: TextField(
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
      ),
    );
  }
}
