import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goaleta/models/goal.dart';
import 'package:intl/intl.dart';

class CongratulationsDialog extends StatelessWidget {
  final Goal goal;
  final VoidCallback onArchive;

  const CongratulationsDialog({
    required this.goal,
    required this.onArchive,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy년 MM월 dd일');
    final duration = DateTime.now().difference(goal.startDate).inDays;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Congratulations SVG
            SvgPicture.asset(
              'assets/images/congratulations.svg',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              '🎉 축하합니다! 🎉',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Goal completion message
            Text(
              '목표를 완료하셨습니다!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Goal title
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                goal.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '시작일',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        dateFormatter.format(goal.startDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '완료일',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        dateFormatter.format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '소요 기간',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '$duration일',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '완료량',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${(goal.totalAmount - goal.startingAmount).toStringAsFixed(0)} ${goal.unit}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Archive message
            Text(
              '이 목표를 보관함으로 이동할까요?',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('나중에'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onArchive();
                    },
                    child: const Text('보관하기'),
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
