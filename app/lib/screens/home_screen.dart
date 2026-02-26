import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/memory_card.dart';
import 'capture_screen.dart';
import 'recall_screen.dart';
import 'identity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  Map<String, dynamic> _stats = {};
  List<dynamic> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await ApiService.getStats();
      final memories = await ApiService.getMemories(limit: 20);
      setState(() { _stats = stats; _memories = memories; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumaColors.bg,
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _MemoryFeed(stats: _stats, memories: _memories, loading: _loading, onRefresh: _load),
            const RecallScreen(),
            const CaptureScreen(),
            const IdentityScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(current: _tab, onTap: (i) => setState(() => _tab = i)),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CaptureScreen()));
                _load();
              },
              backgroundColor: NeumaColors.cyan,
              foregroundColor: NeumaColors.bg,
              icon: const Icon(Icons.add),
              label: const Text('Capture', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ── MEMORY FEED ──────────────────────────────────────────────────────────────
class _MemoryFeed extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<dynamic> memories;
  final bool loading;
  final VoidCallback onRefresh;

  const _MemoryFeed({
    required this.stats, required this.memories,
    required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: NeumaColors.cyan,
      backgroundColor: NeumaColors.surface,
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('Neuma',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [NeumaColors.cyan, NeumaColors.indigo],
                            ).createShader(const Rect.fromLTWH(0, 0, 100, 40)),
                        )),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: NeumaColors.textSub),
                        onPressed: onRefresh),
                    ],
                  ),
                  Text('Your memory consciousness',
                    style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),

                  // Stats row
                  if (!loading) _StatsRow(stats: stats),
                  if (loading) const _StatsLoading(),
                  const SizedBox(height: 24),

                  Text('Recent Memories',
                    style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('${memories.length} memories captured',
                    style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Memory list
          if (loading)
            const SliverToBoxAdapter(child: _LoadingShimmer())
          else if (memories.isEmpty)
            SliverToBoxAdapter(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => MemoryCard(memory: memories[i], index: i),
                  childCount: memories.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard('Memories', '${stats['total_memories'] ?? 0}', NeumaColors.cyan, '🧠'),
        const SizedBox(width: 10),
        _StatCard('People', '${stats['people_count'] ?? 0}', NeumaColors.indigo, '👥'),
        const SizedBox(width: 10),
        _StatCard('Identity', '${stats['identity_count'] ?? 0}', NeumaColors.layerValues, '⭐'),
        const SizedBox(width: 10),
        _StatCard('Values', '${stats['values_count'] ?? 0}', NeumaColors.layerNarrative, '💎'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _StatCard(this.label, this.value, this.color, this.emoji);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: NeumaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
              style: const TextStyle(color: NeumaColors.textDim, fontSize: 10),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 80,
    child: Center(child: CircularProgressIndicator(color: NeumaColors.cyan, strokeWidth: 2)));
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(40),
      child: CircularProgressIndicator(color: NeumaColors.cyan, strokeWidth: 2)));
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🧠', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('No memories yet', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Tap + Capture to store your first memory',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center),
      ]),
    ));
}

// ── BOTTOM NAV ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeumaColors.surface,
        border: Border(top: BorderSide(color: NeumaColors.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, label: 'Home',     idx: 0, current: current, onTap: onTap),
              _NavItem(icon: Icons.search,        label: 'Recall',   idx: 1, current: current, onTap: onTap),
              _NavItem(icon: Icons.mic_outlined,  label: 'Capture',  idx: 2, current: current, onTap: onTap),
              _NavItem(icon: Icons.person_outline,label: 'Identity', idx: 3, current: current, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int idx, current;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.label,
    required this.idx, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = idx == current;
    return GestureDetector(
      onTap: () => onTap(idx),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? NeumaColors.cyan : NeumaColors.textDim, size: 22),
          const SizedBox(height: 4),
          Text(label,
            style: TextStyle(
              color: active ? NeumaColors.cyan : NeumaColors.textDim,
              fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}
