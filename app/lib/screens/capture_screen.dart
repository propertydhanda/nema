import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  bool _saving = false;
  Map<String, dynamic>? _result;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _saving = true; _result = null; });
    try {
      final r = await ApiService.capture(text: _ctrl.text.trim());
      setState(() { _result = r; _saving = false; });
      _ctrl.clear();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: NeumaColors.negative));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumaColors.bg,
      appBar: AppBar(
        backgroundColor: NeumaColors.bg,
        elevation: 0,
        title: const Text('Capture Memory',
          style: TextStyle(color: NeumaColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Mic button (decorative for now)
            Center(
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NeumaColors.surface,
                    border: Border.all(
                      color: NeumaColors.cyan.withOpacity(0.3 + _pulseCtrl.value * 0.4),
                      width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: NeumaColors.cyan.withOpacity(0.1 + _pulseCtrl.value * 0.15),
                        blurRadius: 30 + _pulseCtrl.value * 20,
                        spreadRadius: 5),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: NeumaColors.cyan, size: 36),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 8),
            const Center(
              child: Text('Voice coming soon — type below',
                style: TextStyle(color: NeumaColors.textDim, fontSize: 12))),

            const SizedBox(height: 32),

            Text('What\'s on your mind?',
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('A thought, memory, belief, experience — anything.',
              style: TextStyle(color: NeumaColors.textDim, fontSize: 13)),
            const SizedBox(height: 12),

            // Text input
            TextField(
              controller: _ctrl,
              maxLines: 6,
              style: const TextStyle(color: NeumaColors.textPrimary, fontSize: 15, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'e.g. I had an incredible conversation with my son today...',
              ),
            ),

            const SizedBox(height: 20),

            // Capture button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _capture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeumaColors.cyan,
                  foregroundColor: NeumaColors.bg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: NeumaColors.cyanDim.withOpacity(0.3),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: NeumaColors.bg, strokeWidth: 2))
                    : const Text('Capture Memory',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),

            // Result card
            if (_result != null) ...[
              const SizedBox(height: 24),
              _ResultCard(result: _result!),
            ],

            const SizedBox(height: 40),

            // Quick prompts
            Text('Quick prompts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                'Something I learned today',
                'A person I\'m grateful for',
                'A belief I hold strongly',
                'Something I want to achieve',
                'A memory from childhood',
                'Something I fear',
              ].map((p) => GestureDetector(
                onTap: () => _ctrl.text = p,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: NeumaColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NeumaColors.border),
                  ),
                  child: Text(p,
                    style: const TextStyle(color: NeumaColors.textSub, fontSize: 12)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final layer = result['layer'] ?? 'episodic';
    final meta = layerMap[layer] ?? layerMap['episodic']!;
    final emotion = result['emotion'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeumaColors.positive.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NeumaColors.positive.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle, color: NeumaColors.positive, size: 18),
            const SizedBox(width: 8),
            const Text('Memory captured!',
              style: TextStyle(color: NeumaColors.positive, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
              child: Text('${meta.emoji} ${meta.label}',
                style: TextStyle(color: meta.color, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NeumaColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8)),
              child: Text('${_moodEmoji(emotion['valence'] ?? 0.0)} ${emotion['certainty'] ?? 'certain'}',
                style: const TextStyle(color: NeumaColors.textSub, fontSize: 12)),
            ),
          ]),
          if ((emotion['emotion_tags'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [
              for (final tag in emotion['emotion_tags'] as List)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NeumaColors.indigo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(tag,
                    style: const TextStyle(color: NeumaColors.indigo, fontSize: 11)),
                ),
            ]),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  String _moodEmoji(double v) => v > 0.2 ? '😊' : v < -0.2 ? '😔' : '😐';
}
