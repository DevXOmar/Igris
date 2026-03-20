import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_system.dart';
import '../../../models/rival.dart';
import '../../../widgets/ui/igris_card.dart';

/// Lightweight node-based rival network visualization.
///
/// - Nodes: glowing circles, slow sine float (no physics)
/// - Edges: CustomPainter lines, brighten when selected
/// - Interaction: tap node -> expand card near node, dim others
/// - Tap outside -> collapse
class RivalNetworkView extends StatefulWidget {
  final List<Rival> rivals;

  const RivalNetworkView({required this.rivals, super.key});

  @override
  State<RivalNetworkView> createState() => _RivalNetworkViewState();
}

class _RivalNetworkViewState extends State<RivalNetworkView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t;

  /// Stable order in which rivals first appeared in this view.
  final List<String> _idOrder = <String>[];
  final Set<String> _idOrderSet = <String>{};

  String? _selectedId;
  Offset? _selectedAnchor; // in local coordinates

  @override
  void initState() {
    super.initState();
    _syncIdOrder(widget.rivals);
    _t = AnimationController(vsync: this, duration: 12.seconds)..repeat();
  }

  @override
  void didUpdateWidget(covariant RivalNetworkView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.rivals, widget.rivals)) {
      _syncIdOrder(widget.rivals);
    }
  }

  void _syncIdOrder(List<Rival> rivals) {
    final incoming = <String>{for (final r in rivals) r.id};

    // Drop ids that no longer exist.
    _idOrder.removeWhere((id) => !incoming.contains(id));
    _idOrderSet
      ..clear()
      ..addAll(_idOrder);

    // Append any new ids (always to the end) so "newly created" rivals
    // naturally extend the chain.
    for (final r in rivals) {
      if (_idOrderSet.add(r.id)) {
        _idOrder.add(r.id);
      }
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byId = <String, Rival>{for (final r in widget.rivals) r.id: r};
    final orderedAll = <Rival>[];
    for (final id in _idOrder) {
      final r = byId[id];
      if (r != null) orderedAll.add(r);
    }

    final rivals = _limitRivals(orderedAll);
    final connectOrder = <String>[for (final r in rivals) r.id];
    final selectedRival = _selectedId == null ? null : byId[_selectedId!];

    // If the selected rival was trimmed out (e.g., >30 rivals), clear selection.
    if (_selectedId != null && !connectOrder.contains(_selectedId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedId = null;
          _selectedAnchor = null;
        });
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final nodes = _buildNodes(rivals, connectOrder: connectOrder);

        final rawPositions = <String, Offset>{
          for (final n in nodes)
            n.id: Offset(n.position.dx * size.width, n.position.dy * size.height),
        };

        final positions = _resolveNodeCollisions(
          nodes: nodes,
          positions: rawPositions,
          viewportSize: size,
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_selectedId != null) {
              setState(() {
                _selectedId = null;
                _selectedAnchor = null;
              });
            }
          },
          child: Stack(
            children: [
              // Background
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundPrimary,
                  ),
                ),
              ),

              // Edges
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _t,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _ConnectionsPainter(
                          t: _t.value,
                          nodes: nodes,
                          basePositions: positions,
                          selectedId: _selectedId,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Nodes
              ...nodes.map((node) {
                final base = positions[node.id]!;
                return Positioned(
                  left: base.dx,
                  top: base.dy,
                  child: _RivalNode(
                    node: node,
                    controller: _t,
                    isSelected: _selectedId == node.id,
                    dimmed: _selectedId != null && _selectedId != node.id,
                    onTap: () {
                      setState(() {
                        _selectedId = node.id;
                        _selectedAnchor = base;
                      });
                    },
                  ),
                );
              }),

              // Expanded card
              if (selectedRival != null && _selectedAnchor != null)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: _ExpandedRivalCardOverlay(
                      rival: selectedRival,
                      anchor: _selectedAnchor!,
                      viewportSize: size,
                      onClose: () {
                        setState(() {
                          _selectedId = null;
                          _selectedAnchor = null;
                        });
                      },
                    )
                        .animate()
                        .fadeIn(duration: 180.ms)
                        .scale(
                          begin: const Offset(0.98, 0.98),
                          end: const Offset(1, 1),
                          duration: 220.ms,
                          curve: Curves.easeOut,
                        ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

List<Rival> _limitRivals(List<Rival> rivals) {
  // Keep the network readable.
  if (rivals.length <= 30) return rivals;
  return rivals.sublist(rivals.length - 30);
}

double _baseNodeSizeForThreat(int? threatLevel) {
  final t = threatLevel ?? 0;
  return switch (t) {
    0 || 1 || 2 => 14.0,
    3 => 18.0,
    4 => 20.0,
    _ => 22.0,
  };
}

Color _categoryAccent(RivalCategory c) {
  switch (c) {
    case RivalCategory.proximal:
      return AppColors.neonBlue;
    case RivalCategory.apex:
      return AppColors.shadowPurple;
    case RivalCategory.mythic:
      return AppColors.royalGold;
  }
}

class RivalNetworkNode {
  final String id;
  final Rival rival;
  final RivalCategory category;

  /// Normalized (0..1) position.
  final Offset position;

  /// Connected node ids.
  final List<String> connections;

  const RivalNetworkNode({
    required this.id,
    required this.rival,
    required this.category,
    required this.position,
    required this.connections,
  });
}

List<RivalNetworkNode> _buildNodes(
  List<Rival> rivals, {
  List<String>? connectOrder,
}) {
  if (rivals.isEmpty) return const [];

  // Domain grouping for controlled structure.
  final domains = <String, List<Rival>>{};
  for (final r in rivals) {
    final key = r.domain.trim().isEmpty ? 'Unknown' : r.domain.trim();
    domains.putIfAbsent(key, () => <Rival>[]).add(r);
  }

  final domainKeys = domains.keys.toList()..sort((a, b) => a.compareTo(b));
  final domainCount = domainKeys.length;

  // Deterministic "system map" layout: domains on sectors around center.
  const margin = 0.10;
  final nodes = <RivalNetworkNode>[];
  final idToIndexInDomain = <String, int>{};

  for (int di = 0; di < domainKeys.length; di++) {
    final domain = domainKeys[di];
    final list = domains[domain]!;

    // Stable ordering (threat desc, then updated desc, then name).
    list.sort((a, b) {
      final ta = a.threatLevel ?? 0;
      final tb = b.threatLevel ?? 0;
      final byThreat = tb.compareTo(ta);
      if (byThreat != 0) return byThreat;
      final byUpdated = b.lastUpdated.compareTo(a.lastUpdated);
      if (byUpdated != 0) return byUpdated;
      return a.name.compareTo(b.name);
    });

    for (int i = 0; i < list.length; i++) {
      idToIndexInDomain[list[i].id] = i;
    }

    final baseAngle = (2 * pi) * (di / max(1, domainCount));

    for (int i = 0; i < list.length; i++) {
      final r = list[i];
      final phase = _stablePhase01(r.id);
      final ring = (i ~/ 4); // 0,1,2...
      final withinRing = i % 4;

      final ringRadius = 0.18 + ring * 0.12;
      final angleJitter = (withinRing - 1.5) * 0.22; // small spread
      final angle = baseAngle + angleJitter + (phase - 0.5) * 0.12;

      final x = 0.5 + ringRadius * cos(angle);
      final y = 0.52 + ringRadius * sin(angle);

      final clamped = Offset(
        x.clamp(margin, 1 - margin),
        y.clamp(margin, 1 - margin),
      );

      nodes.add(
        RivalNetworkNode(
          id: r.id,
          rival: r,
          category: r.category,
          position: clamped,
          connections: const [], // filled next
        ),
      );
    }
  }

  // Build controlled connections.
  final byDomain = <String, List<RivalNetworkNode>>{};
  for (final n in nodes) {
    final d = n.rival.domain.trim().isEmpty ? 'Unknown' : n.rival.domain.trim();
    byDomain.putIfAbsent(d, () => <RivalNetworkNode>[]).add(n);
  }

  final connections = <String, Set<String>>{};
  void link(String a, String b) {
    if (a == b) return;
    connections.putIfAbsent(a, () => <String>{}).add(b);
    connections.putIfAbsent(b, () => <String>{}).add(a);
  }

  for (final entry in byDomain.entries) {
    final list = entry.value;

    // Connect within domain as a clean chain.
    for (int i = 1; i < list.length; i++) {
      link(list[i - 1].id, list[i].id);
    }

    // Connect domain leader to up to 2 others for cohesion.
    if (list.length >= 3) {
      link(list.first.id, list[2].id);
    }
  }

  // Connect the global highest threat node to each domain leader.
  RivalNetworkNode? globalLeader;
  int bestThreat = -1;
  for (final n in nodes) {
    final t = n.rival.threatLevel ?? 0;
    if (t > bestThreat) {
      bestThreat = t;
      globalLeader = n;
    }
  }
  if (globalLeader != null && byDomain.length > 1) {
    for (final entry in byDomain.entries) {
      final leader = entry.value.first;
      link(globalLeader.id, leader.id);
    }
  }

  // Always connect nodes in the order they were created/added to the board.
  // This makes the network feel "alive" as new rivals appear.
  // (We infer order from the view's stable `_idOrder` rather than persistence.)
  if (connectOrder != null && connectOrder.length >= 2) {
    final present = <String>{for (final n in nodes) n.id};
    String? prev;
    for (final id in connectOrder) {
      if (!present.contains(id)) continue;
      if (prev != null) link(prev, id);
      prev = id;
    }
  }

  return nodes
      .map((n) => RivalNetworkNode(
            id: n.id,
            rival: n.rival,
            category: n.category,
            position: n.position,
            connections: (connections[n.id] ?? const <String>{}).toList(),
          ))
      .toList();
}

double _stablePhase01(String input) {
  // Stable 0..1 for a string.
  var hash = 0;
  for (final code in input.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return (hash % 10000) / 10000.0;
}

Map<String, Offset> _resolveNodeCollisions({
  required List<RivalNetworkNode> nodes,
  required Map<String, Offset> positions,
  required Size viewportSize,
}) {
  if (nodes.length <= 1) return positions;

  // A bit of extra space so subtle float (±4px) doesn't cause touches.
  const gapPx = 12.0;
  const paddingPx = 16.0;

  final pos = <String, Offset>{...positions};
  final ids = <String>[for (final n in nodes) n.id];

  final radii = <String, double>{
    for (final n in nodes)
      n.id: (_baseNodeSizeForThreat(n.rival.threatLevel) / 2) + gapPx,
  };

  Offset clampCenter(Offset p, double r) {
    final minX = paddingPx + r;
    final maxX = max(minX, viewportSize.width - paddingPx - r);
    final minY = paddingPx + r;
    final maxY = max(minY, viewportSize.height - paddingPx - r);
    return Offset(
      p.dx.clamp(minX, maxX),
      p.dy.clamp(minY, maxY),
    );
  }

  // Iterative relaxation — cheap and stable at <=30 nodes.
  for (int iter = 0; iter < 14; iter++) {
    var movedAny = false;

    for (int i = 0; i < ids.length; i++) {
      final a = ids[i];
      for (int j = i + 1; j < ids.length; j++) {
        final b = ids[j];
        final p1 = pos[a]!;
        final p2 = pos[b]!;

        final delta = p2 - p1;
        final dist = delta.distance;
        final minDist = (radii[a] ?? 0) + (radii[b] ?? 0);

        if (dist >= minDist) continue;

        final dir = dist < 0.001
            ? Offset(
                cos((_stablePhase01(a) + _stablePhase01(b)) * 2 * pi),
                sin((_stablePhase01(a) + _stablePhase01(b)) * 2 * pi),
              )
            : (delta / dist);

        // Split correction equally.
        final push = (minDist - dist) / 2;
        var newP1 = p1 - dir * push;
        var newP2 = p2 + dir * push;

        newP1 = clampCenter(newP1, radii[a] ?? 0);
        newP2 = clampCenter(newP2, radii[b] ?? 0);

        pos[a] = newP1;
        pos[b] = newP2;
        movedAny = true;
      }
    }

    if (!movedAny) break;
  }

  return pos;
}

class _RivalNode extends StatelessWidget {
  final RivalNetworkNode node;
  final AnimationController controller;
  final bool isSelected;
  final bool dimmed;
  final VoidCallback onTap;

  const _RivalNode({
    required this.node,
    required this.controller,
    required this.isSelected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseSize = _baseNodeSizeForThreat(node.rival.threatLevel);

    final accent = _categoryAccent(node.category);
    final phase = _stablePhase01(node.id) * 2 * pi;
    const floatAmp = 4.0; // 2–5px target

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final time = controller.value * 2 * pi;
        final dx = sin(time + phase) * floatAmp;
        final dy = cos(time * 0.9 + phase * 1.1) * (floatAmp * 0.85);
        final breathe = 1 + 0.05 * sin(time * 0.8 + phase);
        final selectedScale = isSelected ? 2.5 : 1.0;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.translate(
            // Center the node on its Positioned anchor.
            offset: Offset(-baseSize / 2, -baseSize / 2),
            child: Opacity(
              opacity: dimmed ? 0.32 : 1.0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Transform.scale(
                  scale: breathe * selectedScale,
                  child: Semantics(
                    button: true,
                    label: node.rival.name,
                    hint: 'Open rival details card',
                    child: Container(
                      width: baseSize,
                      height: baseSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.20),
                        border: Border.all(
                          color: accent.withValues(
                            alpha: isSelected ? 0.95 : 0.55,
                          ),
                          width: isSelected ? 1.6 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(
                              alpha: isSelected ? 0.42 : 0.20,
                            ),
                            blurRadius: isSelected ? 22 : 14,
                            spreadRadius: isSelected ? 3 : 1,
                          ),
                          BoxShadow(
                            color: AppColors.shadowPurple.withValues(
                              alpha: isSelected ? 0.18 : 0.06,
                            ),
                            blurRadius: isSelected ? 26 : 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: baseSize * 0.35,
                                height: baseSize * 0.35,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.65),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionsPainter extends CustomPainter {
  final double t;
  final List<RivalNetworkNode> nodes;
  final Map<String, Offset> basePositions;
  final String? selectedId;

  _ConnectionsPainter({
    required this.t,
    required this.nodes,
    required this.basePositions,
    required this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final phase = t * 2 * pi;

    final idToNode = <String, RivalNetworkNode>{
      for (final n in nodes) n.id: n,
    };

    final drawn = <String>{};

    for (final n in nodes) {
      for (final otherId in n.connections) {
        final a = n.id;
        final b = otherId;
        final key = a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
        if (drawn.contains(key)) continue;
        drawn.add(key);

        final other = idToNode[b];
        if (other == null) continue;

        final p1 = _floatPos(basePositions[a]!, a, phase);
        final p2 = _floatPos(basePositions[b]!, b, phase);

        final isConnectedToSelected = selectedId != null &&
            (a == selectedId || b == selectedId ||
                (idToNode[selectedId!]?.connections.contains(a) ?? false) ||
                (idToNode[selectedId!]?.connections.contains(b) ?? false));

        final baseOpacity =
          selectedId == null ? 0.26 : (isConnectedToSelected ? 0.62 : 0.10);
        final stroke = selectedId == null ? 1.35 : (isConnectedToSelected ? 1.9 : 1.1);

        final color = (isConnectedToSelected
                ? AppColors.neonBlue
                : AppColors.shadowPurple)
            .withValues(alpha: baseOpacity);

        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color;

        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  Offset _floatPos(Offset base, String id, double phase) {
    final p = _stablePhase01(id) * 2 * pi;
    const floatAmp = 4.0;
    final dx = sin(phase + p) * floatAmp;
    final dy = cos(phase * 0.9 + p * 1.1) * (floatAmp * 0.85);
    return base + Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant _ConnectionsPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.nodes.length != nodes.length ||
        oldDelegate.basePositions.length != basePositions.length;
  }
}

class _ExpandedRivalCardOverlay extends StatelessWidget {
  final Rival rival;
  final Offset anchor;
  final Size viewportSize;
  final VoidCallback onClose;

  const _ExpandedRivalCardOverlay({
    required this.rival,
    required this.anchor,
    required this.viewportSize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final category = rival.category;
    final accent = _categoryAccent(category);

    const cardWidth = 320.0;
    const cardMaxHeight = 220.0;

    final preferredAbove = anchor.dy > viewportSize.height * 0.55;
    final dx = (anchor.dx - cardWidth / 2)
        .clamp(16.0, viewportSize.width - cardWidth - 16.0);

    final dy = preferredAbove
        ? (anchor.dy - cardMaxHeight - 18)
            .clamp(16.0, viewportSize.height - cardMaxHeight - 16.0)
        : (anchor.dy + 18)
            .clamp(16.0, viewportSize.height - cardMaxHeight - 16.0);

    return Stack(
      children: [
        // Touch catcher (tap outside to close)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
            child: const SizedBox.expand(),
          ),
        ),

        Positioned(
          left: dx,
          top: dy,
          width: cardWidth,
          child: IgrisCard(
            variant: IgrisCardVariant.elevated,
            showGlow: true,
            padding: const EdgeInsets.all(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: cardMaxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          rival.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Pill(
                        label: category.label,
                        color: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _KeyValueRow(label: 'FIELD', value: rival.domain),
                  if (rival.lastAchievement.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _KeyValueRow(
                      label: 'LAST ACHIEVEMENT',
                      value: rival.lastAchievement,
                    ),
                  ],
                  if (rival.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'GAP ANALYSIS',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Text(
                          rival.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.radar,
                        size: DesignSystem.iconSmall,
                        color: accent.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap outside to close',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 14,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          height: 1.0,
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.25,
                ),
          ),
        ),
      ],
    );
  }
}
