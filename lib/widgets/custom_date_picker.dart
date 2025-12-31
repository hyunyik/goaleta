import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? startDate;
  final Set<DateTime> datesWithRecords;

  const CustomDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.startDate,
    this.datesWithRecords = const {},
    Key? key,
  }) : super(key: key);

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasRecord(DateTime date) {
    return widget.datesWithRecords.any((d) => _isSameDay(d, date));
  }

  bool _isStartDate(DateTime date) {
    return widget.startDate != null && _isSameDay(date, widget.startDate!);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final canGoPrevious = DateTime(
            _displayedMonth.year, _displayedMonth.month - 1)
        .isAfter(DateTime(widget.firstDate.year, widget.firstDate.month - 1));
    final canGoNext = DateTime(_displayedMonth.year, _displayedMonth.month + 1)
        .isBefore(DateTime(widget.lastDate.year, widget.lastDate.month + 2));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month/Year selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: canGoPrevious ? _previousMonth : null,
                ),
                Text(
                  DateFormat('yyyy년 MM월').format(_displayedMonth),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: canGoNext ? _nextMonth : null,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, Colors.green, '시작일'),
                const SizedBox(width: 16),
                _buildLegendItem(context, Colors.blue, '기록'),
              ],
            ),
            const SizedBox(height: 16),

            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .map((day) => SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: day == '일'
                                  ? Colors.red
                                  : day == '토'
                                      ? Colors.blue
                                      : Colors.black.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Calendar grid
            SizedBox(
              height: 240,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: 42,
                itemBuilder: (context, index) {
                  final dayOffset = index - firstWeekday;
                  if (dayOffset < 0 || dayOffset >= daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final day = dayOffset + 1;
                  final date = DateTime(
                      _displayedMonth.year, _displayedMonth.month, day);
                  final isSelectable = !date.isBefore(widget.firstDate) &&
                      !date.isAfter(widget.lastDate);
                  final isSelected = _isSameDay(date, _selectedDate);
                  final hasRecord = _hasRecord(date);
                  final isStart = _isStartDate(date);
                  final isToday = _isSameDay(date, DateTime.now());

                  return InkWell(
                    onTap: isSelectable
                        ? () {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : isSelectable
                                        ? Colors.black
                                        : Colors.black.withOpacity(0.3),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          // Marker dots at the bottom
                          if ((hasRecord || isStart) && !isSelected)
                            Positioned(
                              bottom: 4,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isStart)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: EdgeInsets.only(
                                          right: hasRecord ? 2 : 0),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (hasRecord)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  child: const Text('확인'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? startDate,
  Set<DateTime>? datesWithRecords,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => CustomDatePicker(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      startDate: startDate,
      datesWithRecords: datesWithRecords ?? {},
    ),
  );
}
