import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/hive_db_helper.dart';
import '../models/food_item.dart';
import '../services/notification_service.dart';

class ExpiryTrackerScreen extends StatefulWidget {
  const ExpiryTrackerScreen({super.key});

  @override
  State<ExpiryTrackerScreen> createState() => _ExpiryTrackerScreenState();
}

class _ExpiryTrackerScreenState extends State<ExpiryTrackerScreen> {
  List<FoodItem> _items = [];
  String _activeFilter = 'semua';

  // Controllers untuk form tambah bahan
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _daysController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedEmoji = '🥦';

  final List<String> _emojiOptions = [
    '🥦', '🥕', '🍎', '🍅', '🥚', '🧀', '🍗', '🐟', '🥛', '🫙'
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _daysController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Muat data dari Hive
  void _loadItems() {
    setState(() {
      _items = HiveDbHelper.getFoodItems();
    });
  }

  /// Simpan bahan baru ke Hive + jadwalkan notifikasi
  Future<void> _saveFoodItem() async {
    if (_nameController.text.trim().isEmpty) return;

    final daysLeft = int.tryParse(_daysController.text) ?? 3;
    final weight = double.tryParse(_weightController.text) ?? 0.5;
    final price = int.tryParse(_priceController.text) ?? 0;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final item = FoodItem(
      id: id,
      emoji: _selectedEmoji,
      name: _nameController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? 'Umum'
          : _categoryController.text.trim(),
      daysLeft: daysLeft,
      weight: weight,
      price: price,
    );

    await HiveDbHelper.saveFoodItem(item);

    // Jadwalkan notifikasi pengingat 2 hari sebelum kedaluwarsa
    final expiryDate = DateTime.now().add(Duration(days: daysLeft));
    await NotificationService().scheduleExpiryNotification(
      id: int.parse(id) % 100000, // ID numerik untuk notifikasi
      itemName: item.name,
      expiryDate: expiryDate,
      daysBeforeExpiry: daysLeft > 2 ? 2 : 1,
    );

    _nameController.clear();
    _categoryController.clear();
    _daysController.clear();
    _weightController.clear();
    _priceController.clear();
    _selectedEmoji = '🥦';

    _loadItems();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${item.name} berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Hapus bahan dari Hive
  Future<void> _deleteItem(FoodItem item) async {
    await HiveDbHelper.deleteFoodItem(item.id);
    await NotificationService().cancelNotification(
      int.parse(item.id) % 100000,
    );
    _loadItems();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ ${item.name} dihapus'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  /// Filter items berdasarkan status kedaluwarsa
  List<FoodItem> get _filteredItems {
    switch (_activeFilter) {
      case 'kritis':
        return _items.where((i) => i.daysLeft <= 1).toList();
      case 'mendekati':
        return _items.where((i) => i.daysLeft > 1 && i.daysLeft <= 3).toList();
      case 'aman':
        return _items.where((i) => i.daysLeft > 3).toList();
      default:
        return _items;
    }
  }

  Color _statusColor(int daysLeft) {
    if (daysLeft <= 1) return Colors.red;
    if (daysLeft <= 3) return Colors.amber;
    return Colors.green;
  }

  String _statusLabel(int daysLeft) {
    if (daysLeft <= 1) return 'Kritis!';
    if (daysLeft <= 3) return 'Segera';
    return 'Aman';
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '➕ Tambah Bahan Makanan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Pilih emoji
                const Text('Pilih Ikon:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojiOptions.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setSheetState(() => _selectedEmoji = _emojiOptions[i]),
                      child: Container(
                        width: 48, height: 48,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _selectedEmoji == _emojiOptions[i]
                              ? Colors.green.shade100
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: _selectedEmoji == _emojiOptions[i]
                                ? Colors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(_emojiOptions[i], style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Form fields
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bahan *',
                    prefixIcon: Icon(LucideIcons.utensils),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori (misal: Sayuran)',
                    prefixIcon: Icon(LucideIcons.folder),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hari Sebelum Kedaluwarsa *',
                    prefixIcon: Icon(LucideIcons.calendar),
                    border: OutlineInputBorder(),
                    hintText: 'misal: 5',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Berat (kg)',
                          prefixIcon: Icon(LucideIcons.scale),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga (Rp)',
                          prefixIcon: Icon(LucideIcons.wallet),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saveFoodItem,
                  icon: const Icon(LucideIcons.save, color: Colors.white),
                  label: const Text(
                    'Simpan Bahan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = _items.where((i) => i.daysLeft <= 1).length;
    final approachingCount = _items.where((i) => i.daysLeft > 1 && i.daysLeft <= 3).length;
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🥦 Expiry Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner kritis
          if (criticalCount > 0)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ $criticalCount bahan kritis!',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Segera masak untuk kurangi food waste.',
                          style: TextStyle(color: Color(0xBFFFFFFF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('semua', 'Semua (${_items.length})', Colors.green),
                _buildFilterChip('kritis', 'Kritis ⚠️ ($criticalCount)', Colors.red),
                _buildFilterChip('mendekati', 'Segera 🟡 ($approachingCount)', Colors.amber),
                _buildFilterChip('aman', 'Aman ✅', Colors.blue),
              ],
            ),
          ),

          // List bahan
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildFoodCard(filtered[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemSheet,
        backgroundColor: Colors.green,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Tambah Bahan', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color color) {
    final isActive = _activeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard(FoodItem item) {
    final color = _statusColor(item.daysLeft);
    final label = _statusLabel(item.daysLeft);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    item.category,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.scale, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text('${item.weight} kg', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(width: 10),
                      if (item.price > 0) ...[
                        Icon(LucideIcons.wallet, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text('Rp ${item.price}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.daysLeft} hari lagi',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🥗', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            _activeFilter == 'semua'
                ? 'Belum ada bahan makanan'
                : 'Tidak ada bahan di kategori ini',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambahkan\nbahan makanan pertama Anda 🌿',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
