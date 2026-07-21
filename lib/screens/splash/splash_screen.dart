// lib/screens/splash/splash_screen.dart
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plantmitra_1/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 4300);

  late final AnimationController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    Logger.debug('Animated SplashScreen started');
    _controller = AnimationController(vsync: this, duration: _animationDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _openNextScreen();
        }
      });
    _controller.forward();
  }

  Future<void> _openNextScreen() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      Logger.debug(
        user == null
            ? 'Splash: opening login screen'
            : 'Splash: opening home screen for ${user.uid}',
      );
      await Navigator.of(
        context,
      ).pushReplacementNamed(user == null ? '/login' : '/home');
    } catch (error) {
      Logger.error('Splash navigation failed: $error');
      if (mounted) {
        await Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  double _stage(double start, double end) {
    final value = ((_controller.value - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeInOut.transform(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF8),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final gardenOpacity = 1 - _stage(0.70, 0.88);
          final logoProgress = _stage(0.66, 0.92);
          final textProgress = _stage(0.82, 1.0);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.12),
                radius: 1.05,
                colors: <Color>[
                  Color(0xFFFFFFFF),
                  Color(0xFFF4FAF4),
                  Color(0xFFE8F5EA),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Opacity(
                      opacity: gardenOpacity.clamp(0.0, 1.0),
                      child: CustomPaint(
                        painter: _GardenPainter(progress: _controller.value),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.10),
                    child: Transform.scale(
                      scale: _logoScale(logoProgress),
                      child: Opacity(
                        opacity: logoProgress,
                        child: _buildLogo(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: MediaQuery.sizeOf(context).height * 0.64,
                    child: Opacity(
                      opacity: textProgress,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - textProgress)),
                        child: const Column(
                          children: <Widget>[
                            Text(
                              'Jarvis Green',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF174D2B),
                                fontSize: 35,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Grow  •  Share  •  Connect',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'Your greener journey starts here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF69806E),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 54,
                    right: 54,
                    bottom: 36,
                    child: Column(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: _controller.value,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFD7E9D9),
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            color: Color(0xFF607565),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    );
  }

  String get _statusText {
    final value = _controller.value;
    if (value < 0.25) return 'Planting a seed...';
    if (value < 0.48) return 'Adding water and sunshine...';
    if (value < 0.72) return 'Growing something beautiful...';
    return 'Your garden is ready';
  }

  double _logoScale(double progress) {
    if (progress <= 0) return 0.18;
    final elastic = Curves.elasticOut.transform(progress);
    return 0.18 + (0.82 * elastic);
  }

  Widget _buildLogo() {
    return Container(
      width: 230,
      height: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7EDD9), width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x2418864B),
            blurRadius: 34,
            spreadRadius: 4,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo/jarvis_green_logo_transparent.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFF0F8F1),
            child: Center(
              child: Icon(
                Icons.eco_rounded,
                color: Color(0xFF18864B),
                size: 88,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GardenPainter extends CustomPainter {
  const _GardenPainter({required this.progress});

  final double progress;

  double stage(double start, double end) {
    return Curves.easeInOut.transform(
      ((progress - start) / (end - start)).clamp(0.0, 1.0),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final groundY = size.height * 0.61;

    _paintSun(canvas, size);
    _paintWater(canvas, size, centerX, groundY);
    _paintSoil(canvas, centerX, groundY);
    _paintSeed(canvas, centerX, groundY);
    _paintPlant(canvas, centerX, groundY);
  }

  void _paintSoil(Canvas canvas, double centerX, double groundY) {
    final appear = stage(0.0, 0.12);
    final soilPaint = Paint()
      ..color = const Color(0xFF795548).withValues(alpha: appear);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, groundY),
        width: 210 * appear,
        height: 58 * appear,
      ),
      soilPaint,
    );

    final highlight = Paint()
      ..color = const Color(0xFFA87558).withValues(alpha: appear * 0.75)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, groundY - 4),
        width: 165 * appear,
        height: 31 * appear,
      ),
      math.pi * 1.08,
      math.pi * 0.84,
      false,
      highlight,
    );
  }

  void _paintSeed(Canvas canvas, double centerX, double groundY) {
    final seed = stage(0.07, 0.23) * (1 - stage(0.42, 0.57));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, groundY - 14),
        width: 15 * seed,
        height: 23 * seed,
      ),
      Paint()..color = const Color(0xFF5D4037).withValues(alpha: seed),
    );
  }

  void _paintSun(Canvas canvas, Size size) {
    final sun = stage(0.18, 0.43);
    if (sun <= 0) return;
    final position = Offset(size.width * 0.79, size.height * 0.20);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFFFD54F).withValues(alpha: 0.42 * sun),
          const Color(0xFFFFF8D2).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: position, radius: 72));
    canvas.drawCircle(position, 72, glow);
    canvas.drawCircle(
      position,
      24 * sun,
      Paint()..color = const Color(0xFFFFCA28).withValues(alpha: sun),
    );

    final rayPaint = Paint()
      ..color = const Color(0xFFFFC107).withValues(alpha: sun * 0.72)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 8; index++) {
      final angle = (math.pi * 2 / 8) * index;
      canvas.drawLine(
        position + Offset(math.cos(angle), math.sin(angle)) * 36,
        position + Offset(math.cos(angle), math.sin(angle)) * (50 * sun),
        rayPaint,
      );
    }
  }

  void _paintWater(Canvas canvas, Size size, double centerX, double groundY) {
    final water = stage(0.13, 0.40) * (1 - stage(0.46, 0.58));
    if (water <= 0) return;
    for (var index = 0; index < 5; index++) {
      final travel = ((progress * 4.6) + (index * 0.17)) % 1.0;
      final x = centerX - 92 + (index * 22);
      final y = size.height * 0.25 + travel * (groundY - size.height * 0.28);
      _drawDrop(canvas, Offset(x, y), 7, water * (1 - travel * 0.35));
    }
  }

  void _drawDrop(Canvas canvas, Offset center, double radius, double opacity) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 1.5)
      ..quadraticBezierTo(
        center.dx + radius,
        center.dy,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius,
        center.dy,
        center.dx,
        center.dy - radius * 1.5,
      );
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF42A5F5).withValues(alpha: opacity),
    );
  }

  void _paintPlant(Canvas canvas, double centerX, double groundY) {
    final growth = stage(0.34, 0.70);
    if (growth <= 0) return;
    final topY = groundY - (145 * growth);
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stem = Path()
      ..moveTo(centerX, groundY - 7)
      ..cubicTo(
        centerX - 8,
        groundY - 55 * growth,
        centerX + 9,
        groundY - 104 * growth,
        centerX,
        topY,
      );
    canvas.drawPath(stem, stemPaint);

    final leafProgress = stage(0.48, 0.72);
    _drawLeaf(
      canvas,
      Offset(centerX - 2, groundY - 72 * growth),
      -0.72,
      leafProgress,
      const Color(0xFF43A047),
    );
    _drawLeaf(
      canvas,
      Offset(centerX + 2, groundY - 104 * growth),
      0.70,
      leafProgress,
      const Color(0xFF66BB6A),
    );
  }

  void _drawLeaf(
    Canvas canvas,
    Offset origin,
    double angle,
    double scale,
    Color color,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(20, -28, 55, -27, 62, -4)
      ..cubicTo(39, 12, 14, 11, 0, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawLine(
      const Offset(3, 0),
      const Offset(50, -7),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GardenPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
