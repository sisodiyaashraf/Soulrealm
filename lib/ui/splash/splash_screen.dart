import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../level_map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Route to level map screen after 2.8 seconds
    _timer = Timer(const Duration(milliseconds: 2800), _navigateToNext);
  }

  void _navigateToNext() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => const LevelMapScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToNext,
      child: Scaffold(
        backgroundColor: const Color(0xFF07090F),
        body: Stack(
          children: [
            // Background atmospheric radial glow
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.3,
                    colors: [
                      Color(0xFF141938),
                      Color(0xFF090C1A),
                      Color(0xFF05070E),
                    ],
                  ),
                ),
              ),
            ),

            // Animated Embers Canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SplashEmbersPainter(_controller.value),
                  );
                },
              ),
            ),

            // Central Content
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Celestial Rune Icon
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.3 * _pulseAnimation.value),
                            blurRadius: 28,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_fire_department,
                          color: Color(0xFF00E5FF),
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Game title with modern layered glow
                    Text(
                      'SOULREALM',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF4C8CFF).withValues(alpha: 0.8),
                            blurRadius: 24,
                          ),
                          Shadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                            blurRadius: 48,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      'EMBERS OF THE VOID',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 5,
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Modern progress pill indicator
                    Container(
                      width: 140,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 140 * _controller.value,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFFFF2A85)],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'TAP SCREEN TO AWAKEN',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 9,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashEmbersPainter extends CustomPainter {
  final double animationValue;
  final math.Random _random = math.Random(1337);

  _SplashEmbersPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 35; i++) {
      final startX = _random.nextDouble() * size.width;
      final startY = _random.nextDouble() * size.height;
      final speed = 40.0 + _random.nextDouble() * 80.0;

      final currentY = (startY - animationValue * speed) % size.height;
      final radius = 1.0 + _random.nextDouble() * 2.0;
      final isCyan = i % 2 == 0;

      paint.color = (isCyan ? const Color(0xFF00E5FF) : const Color(0xFFFF2A85))
          .withValues(alpha: 0.2 + 0.5 * (1.0 - (currentY / size.height)));

      canvas.drawCircle(Offset(startX, currentY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashEmbersPainter oldDelegate) => true;
}
