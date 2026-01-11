import 'package:flutter/material.dart';
import 'dart:math';

class RunningCat extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double speed; // daily average, affects animation speed
  final Color color;

  const RunningCat({
    required this.progress,
    required this.speed,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  State<RunningCat> createState() => _RunningCatState();
}

// Speech bubble messages
class _CatMessages {
  // 0-25%: Starting messages
  static final List<String> startMessages = [
    '시작이 반이야!',
    '좋은 출발!',
    '차근차근!',
    '화이팅!',
  ];

  // 25-50%: Approaching halfway
  static final List<String> earlyMessages = [
    '잘하고 있어!',
    '절반까지 조금만!',
    '순조롭네!',
    '힘내!',
  ];

  // 50-75%: Over halfway
  static final List<String> midMessages = [
    '절반 넘었어!',
    '거의 다 왔어!',
    '이 속도로!',
    '최고야!',
  ];

  // 75-100%: Nearing the end
  static final List<String> endMessages = [
    '조금만 더!',
    '거의 다 왔어!',
    '끝이 보여!',
    '완주 직전!',
  ];

  // 100%: Completion messages
  static final List<String> completionMessages = [
    '수고했어!',
    '끝났다!',
    '완주했어!',
    '멋져!',
    '최고야!',
    '해냈어!',
  ];

  // Can appear anywhere
  static final List<String> generalMessages = [
    '냥냥!',
    '달리자!',
    '고고!',
    '오늘도 화이팅!',
    '열심히!',
    '좋아!',
    '계속 가자!',
  ];

  static String getMessageForProgress(double progress) {
    final random = Random();
    
    // Show completion message when at 100%
    if (progress >= 1.0) {
      return completionMessages[random.nextInt(completionMessages.length)];
    }
    
    // 30% chance to show general message anywhere
    if (random.nextDouble() < 0.3) {
      return generalMessages[random.nextInt(generalMessages.length)];
    }

    // Select based on progress
    if (progress < 0.25) {
      return startMessages[random.nextInt(startMessages.length)];
    } else if (progress < 0.50) {
      return earlyMessages[random.nextInt(earlyMessages.length)];
    } else if (progress < 0.75) {
      return midMessages[random.nextInt(midMessages.length)];
    } else {
      return endMessages[random.nextInt(endMessages.length)];
    }
  }
}

class _RunningCatState extends State<RunningCat>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  String _currentMessage = '화이팅!';

  @override
  void initState() {
    super.initState();
    final duration = _calculateDuration(widget.speed);
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );
    
    // Only animate if progress < 1.0
    if (widget.progress < 1.0) {
      _controller.repeat();
    }

    // Change bubble text randomly
    _scheduleBubble();
  }

  void _scheduleBubble() {
    Future.delayed(Duration(seconds: Random().nextInt(3) + 4), () {
      if (mounted) {
        setState(() {
          _currentMessage = _CatMessages.getMessageForProgress(widget.progress);
        });
        _scheduleBubble();
      }
    });
  }

  @override
  void didUpdateWidget(RunningCat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _updateAnimationSpeed();
    }
    
    // Stop animation when progress reaches 100%
    if (oldWidget.progress < 1.0 && widget.progress >= 1.0) {
      _controller.stop();
    } else if (oldWidget.progress >= 1.0 && widget.progress < 1.0) {
      // Resume animation if progress goes back below 100%
      _controller.repeat();
    }
  }

  void _updateAnimationSpeed() {
    final duration = _calculateDuration(widget.speed);
    _controller.dispose();
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );
    
    // Only repeat if progress < 1.0
    if (widget.progress < 1.0) {
      _controller.repeat();
    }
  }

  Duration _calculateDuration(double speed) {
    // Faster animation for higher daily average
    // Base duration: 800ms, gets faster as speed increases
    if (speed <= 0) return const Duration(milliseconds: 1200);
    final milliseconds = (1200 / (1 + speed / 10)).clamp(300, 1200).toInt();
    return Duration(milliseconds: milliseconds);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 30,
          height: 50,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Speech bubble (above cat)
              Positioned(
                bottom: 24,
                child: _buildSpeechBubble(),
              ),
              // Cat
              Positioned(
                bottom: 0,
                child: CustomPaint(
                  painter: _CatPainter(
                    progress: widget.progress,
                    animationValue: _controller.value,
                    color: widget.color,
                  ),
                  size: const Size(24, 24),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeechBubble() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _currentMessage,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ),
        // Tail of speech bubble pointing down
        CustomPaint(
          painter: _BubbleTailPainter(color: Colors.white),
          size: const Size(12, 6),
        ),
      ],
    );
  }
}

class _CatPainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color color;

  _CatPainter({
    required this.progress,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final isSitting = progress >= 1.0;

    if (isSitting) {
      // Sitting pose
      // Body (larger, more rounded for sitting)
      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY + 4),
          width: 16,
          height: 14,
        ),
        const Radius.circular(7),
      );
      canvas.drawRRect(bodyRect, paint);

      // Head (circle) - flipped to left
      canvas.drawCircle(
        Offset(centerX - 6, centerY - 1),
        5,
        paint,
      );

      // Ears (triangles) - flipped to left
      final earPath1 = Path()
        ..moveTo(centerX - 4, centerY - 5)
        ..lineTo(centerX - 6, centerY - 9)
        ..lineTo(centerX - 8, centerY - 5)
        ..close();
      canvas.drawPath(earPath1, paint);

      final earPath2 = Path()
        ..moveTo(centerX - 8, centerY - 5)
        ..lineTo(centerX - 10, centerY - 8)
        ..lineTo(centerX - 12, centerY - 5)
        ..close();
      canvas.drawPath(earPath2, paint);

      // Tail (curved upward for sitting) - flipped to right
      final tailPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final tailPath = Path()
        ..moveTo(centerX + 8, centerY + 4)
        ..quadraticBezierTo(
          centerX + 12,
          centerY,
          centerX + 10,
          centerY - 4,
        );
      canvas.drawPath(tailPath, tailPaint);

      // Legs (sitting position - front paws visible)
      final legPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      // Front legs (slightly forward) - flipped to left
      canvas.drawLine(
        Offset(centerX - 2, centerY + 10),
        Offset(centerX - 2, centerY + 14),
        legPaint,
      );
      canvas.drawLine(
        Offset(centerX - 6, centerY + 10),
        Offset(centerX - 6, centerY + 14),
        legPaint,
      );
    } else {
      // Running pose (original animation)
      // Body (oval)
      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY + 2),
          width: 16,
          height: 12,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(bodyRect, paint);

      // Head (circle) - flipped to left
      canvas.drawCircle(
        Offset(centerX - 6, centerY - 2),
        5,
        paint,
      );

      // Ears (triangles) - flipped to left
      final earPath1 = Path()
        ..moveTo(centerX - 4, centerY - 6)
        ..lineTo(centerX - 6, centerY - 10)
        ..lineTo(centerX - 8, centerY - 6)
        ..close();
      canvas.drawPath(earPath1, paint);

      final earPath2 = Path()
        ..moveTo(centerX - 8, centerY - 6)
        ..lineTo(centerX - 10, centerY - 9)
        ..lineTo(centerX - 12, centerY - 6)
        ..close();
      canvas.drawPath(earPath2, paint);

      // Tail (curved with animation) - flipped to right
      final tailPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final tailPath = Path()
        ..moveTo(centerX + 8, centerY + 2)
        ..quadraticBezierTo(
          centerX + 12,
          centerY - 2 + (animationValue * 4 - 2),
          centerX + 10,
          centerY - 6 + (animationValue * 3 - 1.5),
        );
      canvas.drawPath(tailPath, tailPaint);

      // Legs (animated running)
      final legPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      // Front leg - flipped to left
      final frontLegOffset = animationValue < 0.5 ? 0.0 : 2.0;
      canvas.drawLine(
        Offset(centerX - 4, centerY + 8),
        Offset(centerX - 4, centerY + 12 - frontLegOffset),
        legPaint,
      );

      // Back leg - flipped to left
      final backLegOffset = animationValue < 0.5 ? 2.0 : 0.0;
      canvas.drawLine(
        Offset(centerX + 2, centerY + 8),
        Offset(centerX + 2, centerY + 12 - backLegOffset),
        legPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CatPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}

// Painter for speech bubble tail
class _BubbleTailPainter extends CustomPainter {
  final Color color;

  _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2 - 4, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 4, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
