import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../providers/daily_log_provider.dart';
import '../../providers/domain_provider.dart';
import '../../providers/grace_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/rival_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/weekly_stats_provider.dart';

class SystemBootScreen extends ConsumerStatefulWidget {
  final String identityName;

  /// Shows a cinematic boot screen while binding identity and warming up
  /// provider-backed state.
  ///
  /// This screen intentionally covers the root so HomeScreen never flashes
  /// before the transition.
  const SystemBootScreen({super.key, this.identityName = ''});

  /// Pre-warms the boot screen's first paint/text layout so the transition from
  /// the name screen is less likely to hitch.
  ///
  /// This does not navigate or start any boot timers.
  static void prewarm(ThemeData theme) {
    final lines = const [
      'Initializing system...',
      'Binding identity...',
      'Synchronizing neural link...',
      'Calibrating stats...',
      'System ready.',
    ];

    try {
      // Warm up text layout.
      final style = theme.textTheme.titleMedium?.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.9),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      );
      if (style != null) {
        for (final l in lines) {
          final tp = TextPainter(
            text: TextSpan(text: l, style: style),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout(maxWidth: 520);
          // Touch the painter so it isn't tree-shaken as unused.
          tp.computeLineMetrics();
        }
      }

      // Warm up painters/shaders by recording one offscreen picture.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(520, 820);
      const ringSize = Size(180, 180);

      const _SystemBackdropPainter(t: 0).paint(canvas, size);
      const _AuraRingPainter(glow: 0.6).paint(canvas, ringSize);
      recorder.endRecording();
    } catch (_) {
      // Best-effort warmup.
    }
  }

  @override
  ConsumerState<SystemBootScreen> createState() => _SystemBootScreenState();
}

class _SystemBootScreenState extends ConsumerState<SystemBootScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  bool _started = false;
  bool _fxReady = false;

  static const _minBootDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();

    // 3) Make the first frame lightweight: no animated backdrop, no repeated
    // repaint loop. Enable the full FX after the first frame.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _fxReady = true);
      _loop.repeat();
      _start();
    });
  }

  @override
  void dispose() {
    _loop.dispose();
    _fade.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    final initFuture = _initializeApp();

    await Future.wait([
      Future<void>.delayed(_minBootDuration),
      initFuture,
    ]);

    if (!mounted) return;

    await _fade.reverse();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _initializeApp() async {
    await Future<void>.delayed(Duration.zero);

    final name = widget.identityName.trim();
    if (name.isNotEmpty) {
      await ref.read(progressionProvider.notifier).updateName(name);
    }

    ref.read(domainProvider.notifier).loadDomains();
    ref.read(taskProvider.notifier).loadTasks();
    ref.read(dailyLogProvider.notifier).loadTodayLog();

    ref.read(rivalProvider);
    ref.read(graceProvider);
    ref.read(progressionProvider);

    ref.read(weeklyStatsProvider);
    ref.read(effectiveStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final lines = const [
      'Initializing system...',
      'Binding identity...',
      'Synchronizing neural link...',
      'Calibrating stats...',
      'System ready.',
    ];

    return PopScope(
      canPop: false,
      child: FadeTransition(
        opacity: _fade,
        child: Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundPrimary,
                  AppColors.navyDarker,
                ],
              ),
            ),
            child: Stack(
              children: [
                if (_fxReady)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _loop,
                        builder: (context, _) => CustomPaint(
                          painter: _SystemBackdropPainter(t: _loop.value),
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignSystem.spacing16,
                      DesignSystem.spacing16,
                      DesignSystem.spacing16,
                      DesignSystem.spacing16,
                    ),
                    child: Column(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Row(
                            children: [
                              Icon(
                                Icons.memory,
                                size: 18,
                                color: AppColors.neonBlue.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: DesignSystem.spacing8),
                              Text(
                                'SYSTEM_AWAKENING',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.neonBlue
                                          .withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: _fxReady
                                        ? AnimatedBuilder(
                                            animation: _loop,
                                            builder: (context, _) => _AuraRing(t: _loop.value),
                                          )
                                            .animate()
                                            .fadeIn(
                                              duration:
                                                  const Duration(milliseconds: 280),
                                            )
                                            .scale(
                                              begin: const Offset(0.86, 0.86),
                                              end: const Offset(1, 1),
                                              duration:
                                                  const Duration(milliseconds: 360),
                                              curve: Curves.easeOutCubic,
                                            )
                                        : const _AuraRing(t: 0),
                                  ),
                                  const SizedBox(height: DesignSystem.spacing24),
                                  if (!_fxReady)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        lines.first,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: AppColors.textSecondary.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.8,
                                            ),
                                      ),
                                    )
                                  else
                                    ...List.generate(lines.length, (i) {
                                      final isLast = i == lines.length - 1;
                                      final baseStyle = Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: isLast
                                                ? AppColors.neonBlue
                                                : AppColors.textSecondary
                                                    .withValues(alpha: 0.9),
                                            fontWeight: isLast
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            letterSpacing: 0.8,
                                          );

                                      final delayMs = 320 + (i * 520);

                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(lines[i], style: baseStyle),
                                      )
                                          .animate()
                                          .fadeIn(
                                            duration:
                                                const Duration(milliseconds: 320),
                                            delay: Duration(milliseconds: delayMs),
                                          )
                                          .slideY(
                                            begin: 0.18,
                                            end: 0,
                                            curve: Curves.easeOutCubic,
                                            duration:
                                                const Duration(milliseconds: 320),
                                            delay: Duration(milliseconds: delayMs),
                                          );
                                    }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuraRing extends StatelessWidget {
  final double t;

  const _AuraRing({required this.t});

  @override
  Widget build(BuildContext context) {
    final breathe = 0.96 + (math.sin(t * math.pi * 2) * 0.04);
    final rotate = t * math.pi * 2 * 0.08;
    final glow = 0.55 + (math.sin((t + 0.1) * math.pi * 2) * 0.15);

    return Transform.rotate(
      angle: rotate,
      child: Transform.scale(
        scale: breathe,
        child: CustomPaint(
          size: const Size(180, 180),
          painter: _AuraRingPainter(glow: glow.clamp(0.2, 0.9)),
        ),
      ),
    );
  }
}

class _AuraRingPainter extends CustomPainter {
  final double glow;

  const _AuraRingPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final ringRect = Rect.fromCircle(center: center, radius: radius);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..shader = const SweepGradient(
        colors: [
          AppColors.neonBlue,
          AppColors.shadowPurple,
          AppColors.neonBlue,
        ],
      ).createShader(ringRect);

    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = AppColors.neonBlue.withValues(alpha: 0.08 + glow * 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 28);

    final halo2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = AppColors.shadowPurple.withValues(alpha: 0.04 + glow * 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 34);

    canvas.drawCircle(center, radius - 12, halo2);
    canvas.drawCircle(center, radius - 12, halo);
    canvas.drawCircle(center, radius - 12, stroke);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.neonBlue.withValues(alpha: 0.18 + glow * 0.18);

    canvas.drawCircle(center, radius - 26, inner);
  }

  @override
  bool shouldRepaint(covariant _AuraRingPainter oldDelegate) {
    return oldDelegate.glow != glow;
  }
}

class _SystemBackdropPainter extends CustomPainter {
  final double t;

  const _SystemBackdropPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.neonBlue.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    final dx = (math.sin(t * math.pi * 2) * 6);
    final dy = (math.cos(t * math.pi * 2) * 4);

    const step = 42.0;
    for (double x = -step; x <= size.width + step; x += step) {
      canvas.drawLine(
        Offset(x + dx, 0),
        Offset(x + dx, size.height),
        gridPaint,
      );
    }
    for (double y = -step; y <= size.height + step; y += step) {
      canvas.drawLine(
        Offset(0, y + dy),
        Offset(size.width, y + dy),
        gridPaint,
      );
    }

    final p = Paint()
      ..color = AppColors.shadowPurple.withValues(alpha: 0.05)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final count = 34;
    for (int i = 0; i < count; i++) {
      final fx = (i * 97) % 997;
      final fy = (i * 193) % 991;
      final x = (fx / 997.0) * size.width;
      final y = (fy / 991.0) * size.height;
      final wobble = math.sin((t * 2 * math.pi) + (i * 0.7)) * 1.2;
      canvas.drawCircle(
        Offset(x + wobble, y - wobble),
        1.2,
        p,
      );
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          AppColors.backgroundPrimary.withValues(alpha: 0.82),
        ],
        stops: const [0.55, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: math.max(size.width, size.height) * 0.72,
        ),
      );

    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _SystemBackdropPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
