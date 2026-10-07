// lib/splash/appsline_splash.dart
// Splash animado Appsline — sin dependencias externas.
// Requiere Flutter >= 3.27 (usa Color.withValues).

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paleta de marca Appsline
class AppslineColors {
  static const bg = Color(0xFF040A1C);
  static const bgGlow = Color(0xFF0B2A6B);
  static const blueDeep = Color(0xFF1A3FD1);
  static const blue = Color(0xFF2F6BFF);
  static const sky = Color(0xFF4FC3FF);
  static const cyan = Color(0xFF7FE7FF);
  static const magenta = Color(0xFFFF3DA8);
}

class AppslineSplash extends StatefulWidget {
  const AppslineSplash({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(milliseconds: 4200),
    this.tagline = 'INTELIGENCIA QUE CONECTA',
  });

  final Widget nextScreen;
  final Duration duration;
  final String tagline;

  @override
  State<AppslineSplash> createState() => _AppslineSplashState();
}

class _AppslineSplashState extends State<AppslineSplash>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _loop;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _particles = List.generate(
      80,
      (_) => _Particle(
        angle: rnd.nextDouble() * math.pi * 2,
        distance: 0.55 + rnd.nextDouble() * 0.8,
        size: 0.8 + rnd.nextDouble() * 2.4,
        delay: rnd.nextDouble() * 0.4,
      ),
    );

    _main = AnimationController(vsync: this, duration: widget.duration);
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _main.forward().whenComplete(_goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _main.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// Sub-intervalo normalizado de la línea de tiempo principal.
  double _iv(double begin, double end, [Curve curve = Curves.linear]) {
    final t = ((_main.value - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppslineColors.bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_main, _loop]),
        builder: (context, _) {
          final size = MediaQuery.of(context).size;
          final logoSize = math.min(size.width * 0.55, 260.0);

          // ───── Línea de tiempo (0 → 1) ─────
          final implode = _iv(0.00, 0.24);                         // partículas
          final outline = _iv(0.10, 0.36, Curves.easeInOutCubic);  // contorno
          final circuits = _iv(0.24, 0.56);                        // circuitos
          final fill = _iv(0.55, 0.62, Curves.easeOut);            // relleno
          final flash = _iv(0.55, 0.58) * (1 - _iv(0.58, 0.70));   // destello
          final shock = _iv(0.55, 0.82, Curves.easeOutCubic);      // onda
          final shakeT = _iv(0.55, 0.68);                          // temblor
          final pop = _iv(0.56, 0.74, Curves.elasticOut);          // rebote
          final lift = _iv(0.68, 0.80, Curves.easeOutBack);        // subir logo
          final textT = _iv(0.70, 0.88);                           // wordmark
          final tagline = _iv(0.84, 0.94, Curves.easeOut);         // eslogan
          final exit = _iv(0.94, 1.00, Curves.easeInCubic);        // salida

          final shake = math.sin(shakeT * math.pi * 12) * (1 - shakeT) * 10;
          final logoScale = (0.9 + 0.1 * pop) * (1 - 0.18 * lift);
          final textBlock = logoSize * 0.26 + 70;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Fondo con resplandor radial
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.95,
                    colors: [
                      Color.lerp(
                        AppslineColors.bg,
                        AppslineColors.bgGlow,
                        (fill * 0.9 + flash).clamp(0.0, 1.0),
                      )!,
                      AppslineColors.bg,
                    ],
                  ),
                ),
              ),

              // Partículas: implosión + polvo ambiental
              CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  implode: implode,
                  ambient: fill,
                  loop: _loop.value,
                ),
              ),

              // Onda expansiva
              CustomPaint(painter: _ShockwavePainter(shock)),

              // Logo + wordmark
              Center(
                child: Transform.translate(
                  offset: Offset(shake, 0),
                  child: Opacity(
                    opacity: 1 - exit,
                    child: Transform.scale(
                      scale: 1 + 0.8 * exit,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, (1 - lift) * textBlock / 2),
                            child: Transform.scale(
                              scale: logoScale,
                              child: SizedBox(
                                width: logoSize,
                                height: logoSize * 0.85,
                                child: CustomPaint(
                                  painter: _BrainPainter(
                                    outline: outline,
                                    circuits: circuits,
                                    fill: fill,
                                    pulse: _loop.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: textBlock,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                _GlitchWordmark(
                                  progress: textT,
                                  loop: _loop.value,
                                  fontSize: logoSize * 0.26,
                                ),
                                const SizedBox(height: 14),
                                Opacity(
                                  opacity: tagline,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - tagline) * 12),
                                    child: Column(
                                      children: [
                                        Text(
                                          widget.tagline,
                                          style: TextStyle(
                                            color: AppslineColors.cyan
                                                .withValues(alpha: 0.85),
                                            fontSize: 11,
                                            letterSpacing: 4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        _LoaderBar(loop: _loop.value),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Destello de impacto
              IgnorePointer(
                child: ColoredBox(
                  color: const Color(0xFFE6F6FF)
                      .withValues(alpha: (flash * 0.85).clamp(0.0, 1.0)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Cerebro + circuitos
// ═══════════════════════════════════════════════════════════
class _BrainPainter extends CustomPainter {
  _BrainPainter({
    required this.outline,
    required this.circuits,
    required this.fill,
    required this.pulse,
  });

  final double outline, circuits, fill, pulse;

  static const double vw = 200, vh = 170;

  static Path buildOutline() => Path()
    ..moveTo(40, 140)
    ..cubicTo(20, 140, 10, 120, 18, 105)
    ..cubicTo(5, 95, 8, 72, 25, 66)
    ..cubicTo(22, 48, 38, 34, 55, 38)
    ..cubicTo(60, 22, 80, 16, 95, 24)
    ..cubicTo(105, 12, 128, 12, 138, 24)
    ..cubicTo(155, 18, 175, 30, 172, 48)
    ..cubicTo(190, 54, 195, 78, 182, 90)
    ..cubicTo(194, 104, 186, 126, 168, 128)
    ..cubicTo(165, 145, 145, 152, 130, 145)
    ..cubicTo(120, 158, 100, 158, 92, 146)
    ..cubicTo(80, 152, 62, 150, 55, 140)
    ..cubicTo(50, 142, 44, 142, 40, 140)
    ..close();

  static const List<List<Offset>> traces = [
    [Offset(100, 150), Offset(100, 95), Offset(92, 85), Offset(92, 40)],
    [Offset(108, 150), Offset(108, 90), Offset(118, 78), Offset(118, 38)],
    [Offset(92, 68), Offset(76, 54), Offset(76, 44)],
    [Offset(92, 84), Offset(72, 66), Offset(56, 66)],
    [Offset(97, 104), Offset(74, 86), Offset(46, 86)],
    [Offset(97, 116), Offset(82, 128), Offset(58, 128)],
    [Offset(118, 58), Offset(134, 46), Offset(150, 46)],
    [Offset(118, 74), Offset(146, 74)],
    [Offset(112, 100), Offset(134, 86), Offset(160, 86)],
    [Offset(112, 114), Offset(142, 114), Offset(154, 102)],
    [Offset(112, 126), Offset(134, 136), Offset(158, 136)],
  ];

  static const List<Offset> freeNodes = [Offset(40, 108), Offset(140, 30)];

  static Path _poly(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    return p;
  }

  static Path _partial(Path src, double t) {
    final out = Path();
    if (t <= 0) return out;
    for (final m in src.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * t), Offset.zero);
    }
    return out;
  }

  void _drawNode(Canvas canvas, Offset c, double scale) {
    if (scale <= 0) return;
    final r = 4.2 * scale;
    canvas.drawCircle(
      c,
      r + 2,
      Paint()
        ..color = AppslineColors.cyan.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(c, r, Paint()..color = AppslineColors.blueDeep);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / vw, size.height / vh);
    canvas.save();
    canvas.translate((size.width - vw * s) / 2, (size.height - vh * s) / 2);
    canvas.scale(s);

    final brain = buildOutline();
    const bounds = Rect.fromLTWH(0, 0, vw, vh);

    // Relleno degradado + halo
    if (fill > 0) {
      canvas.drawPath(
        brain,
        Paint()
          ..color = AppslineColors.blue.withValues(alpha: 0.6 * fill)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
      canvas.saveLayer(
        bounds.inflate(10),
        Paint()..color = Colors.black.withValues(alpha: fill),
      );
      canvas.drawPath(
        brain,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppslineColors.sky,
              AppslineColors.blue,
              AppslineColors.blueDeep,
            ],
          ).createShader(bounds),
      );
      canvas.restore();
    }

    // Contorno con neón
    final o = _partial(brain, outline);
    canvas.drawPath(
      o,
      Paint()
        ..color = AppslineColors.cyan.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      o,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Circuitos
    final n = traces.length;
    final glowPaint = Paint()
      ..color = AppslineColors.cyan.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < n; i++) {
      final start = i / n * 0.4;
      final local = ((circuits - start) / 0.45).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final full = _poly(traces[i]);
      final metric = full.computeMetrics().first;
      final part = metric.extractPath(0, metric.length * local);
      canvas.drawPath(part, glowPaint);
      canvas.drawPath(part, linePaint);

      // Chispa en la punta mientras se dibuja
      if (local < 1) {
        final tip = metric.getTangentForOffset(metric.length * local)!.position;
        canvas.drawCircle(
          tip,
          5,
          Paint()
            ..color = AppslineColors.cyan
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(tip, 2, Paint()..color = Colors.white);
      }

      // Nodo final con rebote elástico
      final popT = ((circuits - start - 0.45) / 0.15).clamp(0.0, 1.0);
      _drawNode(canvas, traces[i].last, Curves.elasticOut.transform(popT));

      // Pulsos de datos recorriendo el circuito
      if (fill > 0) {
        final d = (pulse + i * 0.17) % 1.0;
        final pos = metric.getTangentForOffset(metric.length * d)!.position;
        canvas.drawCircle(
          pos,
          4,
          Paint()
            ..color = AppslineColors.cyan.withValues(alpha: fill)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          pos,
          1.8,
          Paint()..color = Colors.white.withValues(alpha: fill),
        );
      }
    }

    final freePop = Curves.elasticOut.transform(
      ((circuits - 0.85) / 0.15).clamp(0.0, 1.0),
    );
    for (final c in freeNodes) {
      _drawNode(canvas, c, freePop);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrainPainter old) => true;
}

// ═══════════════════════════════════════════════════════════
//  Partículas
// ═══════════════════════════════════════════════════════════
class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });
  final double angle, distance, size, delay;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.implode,
    required this.ambient,
    required this.loop,
  });

  final List<_Particle> particles;
  final double implode, ambient, loop;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.longestSide * 0.75;

    for (final p in particles) {
      // 1) Implosión en espiral hacia el centro
      final t = ((implode - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t > 0 && t < 1) {
        final e = Curves.easeInCubic.transform(t);
        final r = maxR * p.distance * (1 - e);
        final a = p.angle + e * 1.4;
        final pos = c + Offset(math.cos(a), math.sin(a)) * r;
        final tail = c + Offset(math.cos(a - 0.08), math.sin(a - 0.08)) *
            (r + 30 * e);
        final color = AppslineColors.cyan.withValues(alpha: 0.2 + 0.8 * e);
        canvas.drawLine(
          tail,
          pos,
          Paint()
            ..color = color.withValues(alpha: 0.35 * e)
            ..strokeWidth = p.size
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(pos, p.size, Paint()..color = color);
      }

      // 2) Polvo ambiental titilante tras el impacto
      if (ambient > 0) {
        final r = maxR * (0.22 + p.distance * 0.42) * (0.75 + 0.25 * ambient);
        final pos = c + Offset(math.cos(p.angle), math.sin(p.angle)) * r;
        final tw = (math.sin(loop * math.pi * 2 + p.angle * 3) + 1) / 2;
        canvas.drawCircle(
          pos,
          p.size * 0.7,
          Paint()
            ..color = AppslineColors.sky
                .withValues(alpha: ambient * (0.15 + 0.55 * tw)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

// ═══════════════════════════════════════════════════════════
//  Onda expansiva
// ═══════════════════════════════════════════════════════════
class _ShockwavePainter extends CustomPainter {
  _ShockwavePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final r = t * size.longestSide * 0.8;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppslineColors.cyan.withValues(alpha: 1 - t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26 * (1 - t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..color = Colors.white.withValues(alpha: (1 - t) * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - t),
    );
  }

  @override
  bool shouldRepaint(covariant _ShockwavePainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════
//  Wordmark con glitch cromático
// ═══════════════════════════════════════════════════════════
class _GlitchWordmark extends StatelessWidget {
  const _GlitchWordmark({
    required this.progress,
    required this.loop,
    required this.fontSize,
  });

  final double progress, loop, fontSize;

  @override
  Widget build(BuildContext context) {
    const word = 'appsline';
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(word.length, (i) {
        final lt = ((progress - i * 0.06) / 0.5).clamp(0.0, 1.0);
        final eased = Curves.easeOutBack.transform(lt);
        final g = math.sin(loop * math.pi * 6 + i * 1.7) * 6 * (1 - lt);
        final ch = word[i];

        return Opacity(
          opacity: lt,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 40),
            child: Stack(
              children: [
                Transform.translate(
                  offset: Offset(-g, 0),
                  child: Text(ch,
                      style: style.copyWith(
                          color: AppslineColors.cyan.withValues(alpha: 0.8))),
                ),
                Transform.translate(
                  offset: Offset(g, 0),
                  child: Text(ch,
                      style: style.copyWith(
                          color:
                              AppslineColors.magenta.withValues(alpha: 0.7))),
                ),
                Text(ch, style: style.copyWith(color: Colors.white)),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Barra de carga
// ═══════════════════════════════════════════════════════════
class _LoaderBar extends StatelessWidget {
  const _LoaderBar({required this.loop});
  final double loop;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 120,
        height: 3,
        child: Stack(
          children: [
            Container(color: Colors.white.withValues(alpha: 0.1)),
            FractionalTranslation(
              translation: Offset(loop * 2 - 1, 0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    AppslineColors.cyan,
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
