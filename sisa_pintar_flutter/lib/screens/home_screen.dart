import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/hive_db_helper.dart';
import '../models/food_item.dart';
import '../models/history_event.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;
  final Function(int) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.onToggleDarkMode,
    required this.isDarkMode,
    required this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, String>> _tips = [
    {
      'emoji': '🥬',
      'title': 'Simpan Bayam dengan Benar',
      'body': 'Bungkus bayam dengan tisu dapur lembab sebelum dimasukkan kulkas agar tahan 5 hari lebih lama.',
    },
    {
      'emoji': '🍚',
      'title': 'Manfaatkan Sisa Nasi',
      'body': 'Nasi sisa kemarin bisa dijadikan nasi goreng lezat dengan telur dan bumbu sederhana.',
    },
    {
      'emoji': '🍌',
      'title': 'Bekukan Buah Matang',
      'body': 'Buah yang terlalu matang bisa dibekukan dan digunakan sebagai bahan smoothie.',
    },
    {
      'emoji': '🧅',
      'title': 'Bawang Tahan Lama',
      'body': 'Simpan bawang di tempat gelap dan kering agar tahan hingga 2 bulan.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _consumeItem(FoodItem item) async {
    final event = HistoryEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: item.name,
      emoji: item.emoji,
      weight: item.weight,
      price: item.price,
      action: 'consumed',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await HiveDbHelper.saveHistoryEvent(event);
    await HiveDbHelper.deleteFoodItem(item.id);
    await NotificationService().cancelNotification(
      int.parse(item.id) % 100000,
    );
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🍳 ${item.name} dikonsumsi & diselamatkan!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _wasteItem(FoodItem item) async {
    final event = HistoryEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: item.name,
      emoji: item.emoji,
      weight: item.weight,
      price: item.price,
      action: 'wasted',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await HiveDbHelper.saveHistoryEvent(event);
    await HiveDbHelper.deleteFoodItem(item.id);
    await NotificationService().cancelNotification(
      int.parse(item.id) % 100000,
    );
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ ${item.name} terbuang'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showItemActionSheet(FoodItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${item.category} • ${item.daysLeft} hari lagi', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _consumeItem(item);
              },
              icon: const Icon(LucideIcons.chefHat, color: Colors.white),
              label: const Text('Sudah Dikonsumsi / Dimasak 🍳', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _wasteItem(item);
              },
              icon: const Icon(LucideIcons.trash2, color: Colors.red),
              label: const Text('Terbuang / Rusak 🗑️', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onNavigateToTab(2);
                    },
                    icon: const Icon(LucideIcons.pencil),
                    label: const Text('Ubah di Tracker'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(LucideIcons.x, color: Colors.grey),
                    label: const Text('Tutup', style: TextStyle(color: Colors.grey)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodItems = HiveDbHelper.getFoodItems();
    final historyEvents = HiveDbHelper.getHistoryEvents();

    final criticalItems = foodItems.where((item) => item.daysLeft <= 2).toList();
    final consumedItems = historyEvents.where((h) => h.action == 'consumed').toList();

    final totalSavedWeight = consumedItems.fold<double>(0, (sum, item) => sum + item.weight);
    final totalSavedMoney = consumedItems.fold<int>(0, (sum, item) => sum + item.price);
    final recipesCookedCount = consumedItems.length + 3;

    final bool hasCritical = criticalItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SisaPintar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 0.5),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                widget.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                key: ValueKey(widget.isDarkMode),
              ),
            ),
            onPressed: widget.onToggleDarkMode,
            tooltip: 'Ganti Tema',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell),
                onPressed: () => widget.onNavigateToTab(2),
              ),
              if (hasCritical)
                Positioned(
                  right: 8,
                  top: 8,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        criticalItems.length.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: Colors.green,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  const Text(
                    'Selamat datang, Mohammed! 👋',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      hasCritical
                          ? '⚠️ Kamu punya ${criticalItems.length} bahan yang hampir kedaluwarsa!'
                          : '✅ Semua bahan makananmu aman! 🌿',
                      key: ValueKey(hasCritical),
                      style: TextStyle(
                        fontSize: 13,
                        color: hasCritical ? Colors.orange.shade700 : Colors.green.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hero Eco Card
                  _buildHeroCard(totalSavedWeight, totalSavedMoney, recipesCookedCount, hasCritical),
                  const SizedBox(height: 16),

                  // Critical items horizontal scroll (only if exists)
                  if (hasCritical) ...[
                    Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Bahan Segera Kedaluwarsa',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateToTab(2),
                          child: const Text('Lihat semua →', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: criticalItems.length,
                        itemBuilder: (_, i) {
                          final item = criticalItems[i];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 300 + i * 80),
                            builder: (_, v, child) => Opacity(opacity: v, child: child),
                            child: GestureDetector(
                              onTap: () => _showItemActionSheet(item),
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Text(item.emoji, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(item.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          Text(
                                            '${item.daysLeft} hari lagi',
                                            style: TextStyle(color: Colors.red.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          title: 'Cari Resep AI',
                          subtitle: 'Dari sisa bahanmu',
                          emoji: '👨‍🍳',
                          color: Colors.green.withValues(alpha: 0.05),
                          accentColor: Colors.green.shade700,
                          onTap: () => widget.onNavigateToTab(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          title: 'Expiry Tracker',
                          subtitle: hasCritical
                              ? '${criticalItems.length} bahan kritis!'
                              : '${foodItems.length} bahan aman',
                          emoji: '📅',
                          color: hasCritical ? Colors.red.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.05),
                          accentColor: hasCritical ? Colors.red.shade700 : Colors.green.shade700,
                          onTap: () => widget.onNavigateToTab(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tips Section
                  Row(
                    children: const [
                      Text('💡', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text('Tips Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tips.length,
                      itemBuilder: (_, i) {
                        final tip = _tips[i];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + i * 100),
                          builder: (_, v, child) => Opacity(opacity: v, child: child),
                          child: _buildTipCard(
                              '${tip['emoji']} ${tip['title']}', tip['body']!),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(double weight, int money, int recipes, bool hasCritical) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasCritical
              ? [const Color(0xFFE65100), const Color(0xFFBF360C)]
              : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasCritical ? Colors.orange : Colors.green).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🌿', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'Dampak Eco-mu Minggu Ini',
                style: TextStyle(color: Color(0xE5FFFFFF), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${weight.toStringAsFixed(1)} kg',
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
          ),
          const Text('makanan diselamatkan', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '💰 Rp $money dihemat',
                  style: const TextStyle(color: Color(0xE5FFFFFF), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  '🍳 $recipes resep dimasak',
                  style: const TextStyle(color: Color(0xE5FFFFFF), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(String title, String body) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              body,
              style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
