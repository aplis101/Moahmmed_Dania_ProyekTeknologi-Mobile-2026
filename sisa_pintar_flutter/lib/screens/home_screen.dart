import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/hive_db_helper.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;
  final Function(int) onNavigateToTab;

  const HomeScreen({
    Key? key,
    required this.onToggleDarkMode,
    required this.isDarkMode,
    required this.onNavigateToTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dynamic queries from Hive
    final foodItems = HiveDbHelper.getFoodItems();
    final historyEvents = HiveDbHelper.getHistoryEvents();

    final criticalItems = foodItems.where((item) => item.daysLeft <= 2).toList();
    final consumedItems = historyEvents.where((h) => h.action == 'consumed').toList();

    final totalSavedWeight = consumedItems.fold<double>(0, (sum, item) => sum + item.weight);
    final totalSavedMoney = consumedItems.fold<int>(0, (sum, item) => sum + item.price);
    final recipesCookedCount = consumedItems.length + 3; // base recipes count

    String statusText = 'Semua bahan makananmu aman untuk saat ini! 🌿';
    Color statusColor = Colors.green;
    if (criticalItems.isNotEmpty) {
      statusText = 'Kamu punya ${criticalItems.length} bahan yang hampir kedaluwarsa!';
      statusColor = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SisaPintar', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 0.5),
        ),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? LucideIcons.sun : LucideIcons.moon),
            onPressed: onToggleDarkMode,
            tooltip: 'Ganti Tema',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell),
                onPressed: () {},
              ),
              if (criticalItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      criticalItems.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat Pagi, Mohammed! 👋',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                statusText,
                style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Eco Impact Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
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
                      '${totalSavedWeight.toStringAsFixed(1)} kg', 
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                    ),
                    const Text(
                      'makanan diselamatkan', 
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.white24, height: 1),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '💰 Rp ${totalSavedMoney.toString()} dihemat', 
                            style: const TextStyle(color: Color(0xE5FFFFFF), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '🍳 $recipesCookedCount resep dimasak', 
                            style: const TextStyle(color: Color(0xE5FFFFFF), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Cari Resep AI',
                      subtitle: 'Dari sisa bahanmu',
                      emoji: '👨‍🍳',
                      color: Colors.green.shade50,
                      iconColor: Colors.green.shade700,
                      onTap: () => onNavigateToTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Expiry Tracker',
                      subtitle: criticalItems.isNotEmpty 
                          ? '${criticalItems.length} bahan kritis!' 
                          : 'Bahan aman',
                      emoji: '📅',
                      color: criticalItems.isNotEmpty ? Colors.red.shade50 : Colors.green.shade50,
                      iconColor: criticalItems.isNotEmpty ? Colors.red.shade700 : Colors.green.shade700,
                      onTap: () => onNavigateToTab(2),
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
                  Text(
                    'Tips Hari Ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTipCard('🥬 Simpan Bayam dengan Benar', 'Bungkus bayam dengan tisu dapur lembab sebelum dimasukkan kulkas agar tahan 5 hari lebih lama.'),
                    _buildTipCard('🍚 Manfaatkan Sisa Nasi', 'Nasi sisa kemarin bisa dijadikan nasi goreng lezat dengan telur dan bumbu sederhana.'),
                    _buildTipCard('🍌 Bekukan Buah Matang', 'Buah yang terlalu matang bisa dibekukan dan digunakan sebagai bahan smoothie.'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(String title, String body) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.1)),
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
              style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }
}
