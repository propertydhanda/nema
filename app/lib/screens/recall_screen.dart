import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/memory_card.dart';

class RecallScreen extends StatefulWidget {
  const RecallScreen({super.key});
  @override
  State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen> {
  final _ctrl = TextEditingController();
  List<dynamic> _results = [];
  bool _searching = false;
  bool _searched = false;

  Future<void> _search() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() { _searching = true; _results = []; });
    try {
      final r = await ApiService.recall(query: _ctrl.text.trim(), limit: 10);
      setState(() { _results = r; _searching = false; _searched = true; });
    } catch (e) {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumaColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Recall', style: Theme.of(context).textTheme.displayLarge
                  ?.copyWith(color: NeumaColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Ask anything about your past',
                style: TextStyle(color: NeumaColors.textDim, fontSize: 13)),
              const SizedBox(height: 20),

              // Search bar
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _search(),
                    style: const TextStyle(color: NeumaColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'e.g. "times I felt proud" or "my values around family"',
                      prefixIcon: Icon(Icons.search, color: NeumaColors.textDim, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _searching ? null : _search,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: NeumaColors.cyan,
                      borderRadius: BorderRadius.circular(12)),
                    child: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: NeumaColors.bg, strokeWidth: 2))
                        : const Icon(Icons.arrow_forward, color: NeumaColors.bg),
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // Suggestion chips
              if (!_searched) ...[
                Wrap(spacing: 8, runSpacing: 8, children: [
                  'times I felt proud',
                  'my biggest fears',
                  'people who shaped me',
                  'what I believe in',
                  'spiritual experiences',
                  'career wins',
                ].map((s) => GestureDetector(
                  onTap: () { _ctrl.text = s; _search(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: NeumaColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: NeumaColors.border),
                    ),
                    child: Text(s,
                      style: const TextStyle(color: NeumaColors.textSub, fontSize: 12)),
                  ),
                )).toList()),
              ],

              const SizedBox(height: 16),

              // Results
              if (_searching)
                const Expanded(child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: NeumaColors.cyan, strokeWidth: 2),
                    SizedBox(height: 16),
                    Text('Searching your memories...',
                      style: TextStyle(color: NeumaColors.textDim)),
                  ])))
              else if (_searched && _results.isEmpty)
                const Expanded(child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('🔍', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 12),
                    Text('No memories found',
                      style: TextStyle(color: NeumaColors.textSub, fontSize: 16)),
                    Text('Try a different search',
                      style: TextStyle(color: NeumaColors.textDim, fontSize: 13)),
                  ])))
              else if (_results.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_results.length} memories found',
                        style: const TextStyle(color: NeumaColors.textDim, fontSize: 12)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (ctx, i) => MemoryCard(
                            memory: _results[i], index: i),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
