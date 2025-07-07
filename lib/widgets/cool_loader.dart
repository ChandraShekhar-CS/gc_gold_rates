import 'package:flutter/material.dart';
import 'dart:math' as math;

class CoolLoader extends StatefulWidget {
  final String? loadingText;
  final Color? primaryColor;
  final double size;

  const CoolLoader({
    super.key,
    this.loadingText,
    this.primaryColor,
    this.size = 120.0,
  });

  @override
  State<CoolLoader> createState() => _CoolLoaderState();
}

class _CoolLoaderState extends State<CoolLoader> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _rotationController.repeat();
    _fadeController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.primaryColor ?? Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                ),
              ),

              // Rotating arcs
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: CustomPaint(
                      size: Size(widget.size * 0.8, widget.size * 0.8),
                      painter: LoaderPainter(
                        color: primaryColor,
                        progress: _rotationAnimation.value,
                      ),
                    ),
                  );
                },
              ),

              // Center content
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      width: widget.size * 0.4,
                      height: widget.size * 0.4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: onPrimary,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Loading text
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Text(
                widget.loadingText ?? 'Loading GC Gold Rates...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Progress dots
        _buildProgressDots(primaryColor),
      ],
    );
  }

  Widget _buildProgressDots(Color primaryColor) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final progress = (_rotationController.value + delay) % 1.0;
            final opacity = (math.sin(progress * 2 * math.pi) + 1) / 2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.3 + opacity * 0.7),
              ),
            );
          }),
        );
      },
    );
  }
}

class LoaderPainter extends CustomPainter {
  final Color color;
  final double progress;

  LoaderPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw multiple arcs
    for (int i = 0; i < 3; i++) {
      final startAngle = (progress * 2 * math.pi) + (i * 2 * math.pi / 3);
      final sweepAngle = math.pi / 2;
      final opacity = 1.0 - (i * 0.3);

      paint.color = color.withOpacity(opacity);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (i * 8)),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(LoaderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
