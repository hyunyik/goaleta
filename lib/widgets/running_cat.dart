import 'package:flutter/material.dart';

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

class _RunningCatState extends State<RunningCat>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final duration = _calculateDuration(widget.speed);
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(RunningCat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _updateAnimationSpeed();
    }
  }

  void _updateAnimationSpeed() {
    final duration = _calculateDuration(widget.speed);
    _controller.dispose();
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    )..repeat();
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
        return CustomPaint(
          painter: _CatPainter(
            progress: widget.progress,
            animationValue: _controller.value,
            color: widget.color,
          ),
          size: const Size(24, 24),
        );
      },
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

    // Head (circle)
    canvas.drawCircle(
      Offset(centerX + 6, centerY - 2),
      5,
      paint,
    );

    // Ears (triangles)
    final earPath1 = Path()
      ..moveTo(centerX + 4, centerY - 6)
      ..lineTo(centerX + 6, centerY - 10)
      ..lineTo(centerX + 8, centerY - 6)
      ..close();
    canvas.drawPath(earPath1, paint);

    final earPath2 = Path()
      ..moveTo(centerX + 8, centerY - 6)
      ..lineTo(centerX + 10, centerY - 9)
      ..lineTo(centerX + 12, centerY - 6)
      ..close();
    canvas.drawPath(earPath2, paint);

    // Tail (curved)
    final tailPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final tailPath = Path()
      ..moveTo(centerX - 8, centerY + 2)
      ..quadraticBezierTo(
        centerX - 12,
        centerY - 2 + (animationValue * 4 - 2),
        centerX - 10,
        centerY - 6 + (animationValue * 3 - 1.5),
      );
    canvas.drawPath(tailPath, tailPaint);

    // Legs (animated running)
    final legPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Front leg
    final frontLegOffset = animationValue < 0.5 ? 0.0 : 2.0;
    canvas.drawLine(
      Offset(centerX + 4, centerY + 8),
      Offset(centerX + 4, centerY + 12 - frontLegOffset),
      legPaint,
    );

    // Back leg
    final backLegOffset = animationValue < 0.5 ? 2.0 : 0.0;
    canvas.drawLine(
      Offset(centerX - 2, centerY + 8),
      Offset(centerX - 2, centerY + 12 - backLegOffset),
      legPaint,
    );
  }

  @override
  bool shouldRepaint(_CatPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
