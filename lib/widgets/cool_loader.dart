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

class _CoolLoaderState extends State<CoolLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Scale animation for gold coins
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for outer ring
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _rotationController.repeat();
    _scaleController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Colors.amber.shade700;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Middle ring
              Container(
                width: widget.size * 0.8,
                height: widget.size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              
              // Rotating gold coins
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: SizedBox(
                      width: widget.size * 0.7,
                      height: widget.size * 0.7,
                      child: Stack(
                        children: List.generate(6, (index) {
                          final angle = (index * 60) * math.pi / 180;
                          final radius = widget.size * 0.25;
                          return Positioned(
                            left: widget.size * 0.35 + radius * math.cos(angle) - 8,
                            top: widget.size * 0.35 + radius * math.sin(angle) - 8,
                            child: AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value * (0.8 + index * 0.05),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          primaryColor,
                                          primaryColor.withOpacity(0.7),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.3),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
              
              // Center gold coin
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.currency_rupee,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Loading text with fade animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: 0.7 + (_pulseAnimation.value - 0.9) * 1.5,
              child: Text(
                widget.loadingText ?? 'Loading GC Gold Rates...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        // Subtitle with dots animation
        _buildDotsAnimation(),
      ],
    );
  }

  Widget _buildDotsAnimation() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final progress = _rotationController.value;
        final dots = ['⬤', '⬤', '⬤'];
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dots.asMap().entries.map((entry) {
            final index = entry.key;
            final dot = entry.value;
            final opacity = (math.sin((progress * 2 * math.pi) + (index * math.pi / 3)) + 1) / 2;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                dot,
                style: TextStyle(
                  fontSize: 12,
                  color: (widget.primaryColor ?? Colors.amber.shade700)
                      .withOpacity(opacity * 0.8),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}