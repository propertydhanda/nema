import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class MemoryCard extends StatelessWidget {
  final Map<String, dynamic> memory;
  final VoidCallback? onTap;
  final int index;

  const MemoryCard({super.key, required this.memory, this.onTap, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final layer = memory['layer'] ?? 'episodic';
    final meta = layerMap[layer] ?? layerMap['episodic']!;
    final significance = (memory['emotional_significance'] ?? 0.5) as double;
    final valence = (memory['valence'] ?? 0.0) as double;
    final state = memory['consolidation_state'] ?? 'fresh';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: NeumaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NeumaColors.border),
          boxShadow: [
            BoxShadow(
              color: meta.color.withOpacity(0.05),
              blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with layer color
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: meta.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: meta.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(meta.emoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(meta.label,
                              style: TextStyle(
                                color: meta.color, fontSize: 11,
                                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _StateChip(state),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Memory text
                  Text(
                    memory['raw_text'] ?? '',
                    style: const TextStyle(
                      color: NeumaColors.textPrimary,
                      fontSize: 14, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Footer row
                  Row(
                    children: [
                      // Significance bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('IMPORTANCE', style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: significance,
                                backgroundColor: NeumaColors.border,
                                valueColor: AlwaysStoppedAnimation(meta.color),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Mood dot
                      Column(
                        children: [
                          Text('MOOD', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 4),
                          _MoodDot(valence: valence),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Recall count
                      Column(
                        children: [
                          Text('RECALLED', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 4),
                          Text('${memory['retrieval_count'] ?? 0}x',
                            style: const TextStyle(
                              color: NeumaColors.cyan, fontSize: 13,
                              fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),

                  // Location + time if present
                  if (memory['location_label'] != null || memory['event_at'] != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (memory['location_label'] != null) ...[
                          const Icon(Icons.location_on, size: 12, color: NeumaColors.textDim),
                          const SizedBox(width: 3),
                          Text(memory['location_label'],
                            style: const TextStyle(color: NeumaColors.textDim, fontSize: 11)),
                          const SizedBox(width: 12),
                        ],
                        if (memory['event_at'] != null) ...[
                          const Icon(Icons.calendar_today, size: 12, color: NeumaColors.textDim),
                          const SizedBox(width: 3),
                          Text(_formatDate(memory['event_at']),
                            style: const TextStyle(color: NeumaColors.textDim, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60))
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return raw; }
  }
}

class _StateChip extends StatelessWidget {
  final String state;
  const _StateChip(this.state);

  @override
  Widget build(BuildContext context) {
    final config = {
      'fresh':        (NeumaColors.positive, 'Fresh'),
      'consolidating':(NeumaColors.warning, 'Forming'),
      'consolidated': (NeumaColors.cyan, 'Solid'),
      'remote':       (NeumaColors.textDim, 'Remote'),
    }[state] ?? (NeumaColors.textDim, state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.$1.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.$1.withOpacity(0.3)),
      ),
      child: Text(config.$2,
        style: TextStyle(color: config.$1, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _MoodDot extends StatelessWidget {
  final double valence;
  const _MoodDot({required this.valence});

  @override
  Widget build(BuildContext context) {
    final color = valence > 0.2
        ? NeumaColors.positive
        : valence < -0.2
            ? NeumaColors.negative
            : NeumaColors.neutral;
    final emoji = valence > 0.2 ? '😊' : valence < -0.2 ? '😔' : '😐';
    return Text(emoji, style: const TextStyle(fontSize: 16));
  }
}
