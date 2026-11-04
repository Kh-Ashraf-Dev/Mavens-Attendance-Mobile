import 'dart:math' as math;
import 'package:flutter/material.dart';

class WelcomeSplash extends StatefulWidget {
  final VoidCallback onComplete;
  const WelcomeSplash({super.key, required this.onComplete});
  @override
  State<WelcomeSplash> createState() => _WelcomeSplashState();
}

class _WelcomeSplashState extends State<WelcomeSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2800),
        )
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            widget.onComplete();
          }
        })
        ..forward();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xff07172e),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          final reveal = reduced
              ? 1.0
              : Curves.easeOutCubic.transform((t / .55).clamp(0.0, 1.0));
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _OrbitPainter(reduced ? 1 : t)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: .8 + .2 * reveal,
                        child: Opacity(
                          opacity: reveal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 40,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              color: Colors.white.withValues(alpha: .05),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xff4198ed,
                                  ).withValues(alpha: .12),
                                  blurRadius: 80,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/mavens-logo-white.png',
                              width: 240,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 38),
                      Opacity(
                        opacity: reveal,
                        child: Transform.translate(
                          offset: Offset(0, 22 * (1 - reveal)),
                          child: const Column(
                            children: [
                              Text(
                                'Welcome Mavens Team',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 27,
                                  height: 1.3,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'GREAT PEOPLE. GREAT POSSIBILITIES.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: Color(0xff9dbbdd),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 42),
                      SizedBox(
                        width: 90,
                        child: LinearProgressIndicator(
                          value: t,
                          minHeight: 2,
                          color: const Color(0xff67b8ff),
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: 32,
                child: Text(
                  'MAVENS  /  ATTENDANCE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double t;
  _OrbitPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .43);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      paint.color = const Color(0xff66b5ff).withValues(alpha: .09 - i * .02);
      final radius = size.width * (.48 + i * .2);
      canvas.drawCircle(center, radius, paint);
      final angle = t * math.pi * .7 + i * 2;
      canvas.drawCircle(
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        3,
        Paint()..color = const Color(0xff8dceff).withValues(alpha: .7),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => oldDelegate.t != t;
}
