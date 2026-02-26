import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});
  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _statements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await ApiService.getIdentity();
    setState(() { _statements = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumaColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Identity', style: Theme.of(context).textTheme.displayLarge),
                  const Text('Who you are — built from memory',
                    style: TextStyle(color: NeumaColors.textDim, fontSize: 13)),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            TabBar(
              controller: _tabs,
              indicatorColor: NeumaColors.cyan,
              indicatorWeight: 2,
              labelColor: NeumaColors.cyan,
              unselectedLabelColor: NeumaColors.textDim,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: const [
                Tab(text: 'Statements'),
                Tab(text: 'Values'),
                Tab(text: 'Add'),
              ],
            ),

            const Divider(height: 1, color: NeumaColors.border),

            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _StatementsTab(statements: _statements, loading: _loading),
                  _ValuesTab(),
                  _AddTab(onAdded: _load),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementsTab extends StatelessWidget {
  final List<dynamic> statements;
  final bool loading;
  const _StatementsTab({required this.statements, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(
      child: CircularProgressIndicator(color: NeumaColors.cyan, strokeWidth: 2));

    if (statements.isEmpty) return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('⭐', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text('No identity statements yet',
          style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('Add what you know about yourself',
          style: TextStyle(color: NeumaColors.textDim)),
      ]));

    // Group by type
    final grouped = <String, List<dynamic>>{};
    for (final s in statements) {
      final type = s['statement_type'] ?? 'i_am';
      grouped.putIfAbsent(type, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: grouped.entries.map((e) {
        final meta = _typeMeta(e.key);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(meta.$1, style: TextStyle(
                color: meta.$3, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: meta.$3.withOpacity(0.2))),
            ]),
            const SizedBox(height: 8),
            ...e.value.asMap().entries.map((en) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NeumaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: meta.$3.withOpacity(0.2)),
              ),
              child: Row(children: [
                Text(meta.$2, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(en.value['content'] ?? '',
                  style: const TextStyle(color: NeumaColors.textPrimary, fontSize: 14, height: 1.4))),
              ]),
            ).animate(delay: Duration(milliseconds: en.key * 50))
              .fadeIn().slideX(begin: -0.05, end: 0)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  (String, String, Color) _typeMeta(String type) => switch(type) {
    'i_am'          => ('I AM', '🧬', NeumaColors.cyan),
    'i_seek'        => ('I SEEK', '🎯', NeumaColors.indigo),
    'i_avoid'       => ('I AVOID', '🛡️', NeumaColors.warning),
    'i_fear'        => ('I FEAR', '⚡', NeumaColors.negative),
    'i_believe'     => ('I BELIEVE', '💡', NeumaColors.layerValues),
    'i_want'        => ('I WANT', '🚀', NeumaColors.positive),
    'i_am_becoming' => ('BECOMING', '🌱', NeumaColors.layerNarrative),
    _               => ('OTHER', '•', NeumaColors.textSub),
  };
}

class _ValuesTab extends StatefulWidget {
  @override
  State<_ValuesTab> createState() => _ValuesTabState();
}

class _ValuesTabState extends State<_ValuesTab> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Core Values', style: TextStyle(
          color: NeumaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('The principles that guide your decisions',
          style: TextStyle(color: NeumaColors.textDim, fontSize: 13)),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(hintText: 'Value name (e.g. Sovereignty)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'What does this value mean to you?'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : () async {
              if (_nameCtrl.text.isEmpty) return;
              setState(() => _saving = true);
              await ApiService.addStatement(
                type: 'i_believe',
                content: '${_nameCtrl.text}: ${_descCtrl.text}');
              _nameCtrl.clear(); _descCtrl.clear();
              setState(() => _saving = false);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Value saved ✓'),
                  backgroundColor: NeumaColors.positive));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeumaColors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Value', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _AddTab extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddTab({required this.onAdded});
  @override
  State<_AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<_AddTab> {
  String _type = 'i_am';
  final _ctrl = TextEditingController();
  bool _saving = false;

  final _types = [
    ('i_am',          'I am...', '🧬'),
    ('i_seek',        'I seek...', '🎯'),
    ('i_avoid',       'I avoid...', '🛡️'),
    ('i_fear',        'I fear...', '⚡'),
    ('i_believe',     'I believe...', '💡'),
    ('i_want',        'I want...', '🚀'),
    ('i_am_becoming', 'I am becoming...', '🌱'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Add Identity Statement',
          style: TextStyle(color: NeumaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _types.map((t) => GestureDetector(
            onTap: () => setState(() => _type = t.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _type == t.$1 ? NeumaColors.cyan.withOpacity(0.15) : NeumaColors.surfaceHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _type == t.$1 ? NeumaColors.cyan : NeumaColors.border,
                  width: _type == t.$1 ? 1.5 : 1),
              ),
              child: Text('${t.$3} ${t.$2}',
                style: TextStyle(
                  color: _type == t.$1 ? NeumaColors.cyan : NeumaColors.textSub,
                  fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          maxLines: 4,
          style: const TextStyle(color: NeumaColors.textPrimary, fontSize: 15, height: 1.5),
          decoration: InputDecoration(
            hintText: _types.firstWhere((t) => t.$1 == _type).$2,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : () async {
              if (_ctrl.text.trim().isEmpty) return;
              setState(() => _saving = true);
              await ApiService.addStatement(type: _type, content: _ctrl.text.trim());
              _ctrl.clear();
              setState(() => _saving = false);
              widget.onAdded();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statement saved ✓'),
                  backgroundColor: NeumaColors.positive));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeumaColors.cyan,
              foregroundColor: NeumaColors.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: NeumaColors.bg, strokeWidth: 2))
                : const Text('Save Statement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
