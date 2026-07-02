import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../database/hive_db_helper.dart';
import '../models/food_item.dart';
import '../models/history_event.dart';
import '../services/notification_service.dart';
import '../services/localization_service.dart';
import '../main.dart';

class ExpiryTrackerScreen extends StatefulWidget {
  const ExpiryTrackerScreen({super.key});

  @override
  State<ExpiryTrackerScreen> createState() => _ExpiryTrackerScreenState();
}

class _ExpiryTrackerScreenState extends State<ExpiryTrackerScreen> {
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
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _daysController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Simpan bahan baru ke Hive + jadwalkan notifikasi
  Future<void> _saveFoodItem(String lang) async {
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
          ? (lang == 'ar' ? 'عام' : (lang == 'en' ? 'General' : 'Umum'))
          : _categoryController.text.trim(),
      daysLeft: daysLeft,
      weight: weight,
      price: price,
    );

    await HiveDbHelper.saveFoodItem(item);

    // Jadwalkan notifikasi pengingat 2 hari sebelum kedaluwarsa
    final expiryDate = DateTime.now().add(Duration(days: daysLeft));
    await NotificationService().scheduleExpiryNotification(
      id: int.parse(id) % 100000,
      itemName: item.name,
      expiryDate: expiryDate,
      daysBeforeExpiry: daysLeft > 2 ? 2 : 1,
    );

    _nameController.clear();
    _categoryController.clear();
    _daysController.clear();
    _weightController.clear();
    _priceController.clear();
    setState(() => _selectedEmoji = '🥦');

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.get(lang, 'added_success', args: {'name': item.name})),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// حذف عنصر من Hive
  Future<void> _deleteItem(FoodItem item, String lang) async {
    await HiveDbHelper.deleteFoodItem(item.id);
    await NotificationService().cancelNotification(
      int.parse(item.id) % 100000,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.get(lang, 'deleted_msg', args: {'name': item.name})),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _consumeItem(FoodItem item, String lang) async {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.get(lang, 'cooking_done_snack', args: {
            'count': '1',
            'money': item.price.toString()
          })),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _wasteItem(FoodItem item, String lang) async {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.get(lang, 'deleted_msg', args: {'name': item.name})),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showItemActionSheet(FoodItem item, String lang) {
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
                      Text(
                        '${item.category} • ${LocalizationService.get(lang, 'days_left', args: {'count': item.daysLeft.toString()})}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _consumeItem(item, lang);
              },
              icon: const Icon(LucideIcons.chefHat, color: Colors.white),
              label: Text(
                lang == 'ar'
                    ? 'تم الاستهلاك / الطبخ 🍳'
                    : (lang == 'en' ? 'Consumed / Cooked 🍳' : 'Sudah Dikonsumsi / Dimasak 🍳'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
                await _wasteItem(item, lang);
              },
              icon: const Icon(LucideIcons.trash2, color: Colors.red),
              label: Text(
                lang == 'ar'
                    ? 'مهدور / تالف 🗑️'
                    : (lang == 'en' ? 'Wasted / Spoiled 🗑️' : 'Terbuang / Rusak 🗑️'),
                style: const TextStyle(color: Colors.red),
              ),
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
                      _showEditItemSheet(item, lang);
                    },
                    icon: const Icon(LucideIcons.pencil),
                    label: Text(
                      lang == 'ar'
                          ? 'تعديل التفاصيل'
                          : (lang == 'en' ? 'Edit Details' : 'Edit Detail'),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (alertCtx) => AlertDialog(
                          title: Text(LocalizationService.get(lang, 'confirm_delete_title')),
                          content: Text(LocalizationService.get(lang, 'confirm_delete_desc_no_history', args: {'name': item.name})),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(alertCtx, false),
                              child: Text(LocalizationService.get(lang, 'cancel')),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(alertCtx, true),
                              child: Text(
                                lang == 'ar' ? 'حذف' : (lang == 'en' ? 'Delete' : 'Hapus'),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deleteItem(item, lang);
                      }
                    },
                    icon: const Icon(LucideIcons.x, color: Colors.grey),
                    label: Text(
                      lang == 'ar' ? 'حذف' : (lang == 'en' ? 'Delete' : 'Hapus'),
                      style: const TextStyle(color: Colors.grey),
                    ),
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

  /// فتح نافذة التعديل
  void _showEditItemSheet(FoodItem item, String lang) {
    final nameCtrl = TextEditingController(text: item.name);
    final categoryCtrl = TextEditingController(text: item.category);
    final daysCtrl = TextEditingController(text: item.daysLeft.toString());
    final weightCtrl = TextEditingController(text: item.weight.toString());
    final priceCtrl = TextEditingController(text: item.price.toString());
    String selectedEmoji = item.emoji;

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
                Text(
                  LocalizationService.get(lang, 'edit_food_title'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  LocalizationService.get(lang, 'choose_icon'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojiOptions.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setSheetState(() => selectedEmoji = _emojiOptions[i]),
                      child: Container(
                        width: 48, height: 48,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: selectedEmoji == _emojiOptions[i]
                              ? Colors.green.shade100 : Colors.grey.shade100,
                          border: Border.all(
                            color: selectedEmoji == _emojiOptions[i]
                                ? Colors.green : Colors.transparent,
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
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: LocalizationService.get(lang, 'food_name_label'),
                    prefixIcon: const Icon(LucideIcons.utensils),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  decoration: InputDecoration(
                    labelText: LocalizationService.get(lang, 'category_label'),
                    prefixIcon: const Icon(LucideIcons.folder),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: daysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LocalizationService.get(lang, 'days_before_expiry'),
                    prefixIcon: const Icon(LucideIcons.calendar),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: LocalizationService.get(lang, 'weight_label'),
                          prefixIcon: const Icon(LucideIcons.scale),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: LocalizationService.get(lang, 'price_label'),
                          prefixIcon: const Icon(LucideIcons.wallet),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);

                    final updatedItem = FoodItem(
                      id: item.id,
                      emoji: selectedEmoji,
                      name: nameCtrl.text.trim(),
                      category: categoryCtrl.text.trim().isEmpty ? 'Umum' : categoryCtrl.text.trim(),
                      daysLeft: int.tryParse(daysCtrl.text) ?? item.daysLeft,
                      weight: double.tryParse(weightCtrl.text) ?? item.weight,
                      price: int.tryParse(priceCtrl.text) ?? item.price,
                    );
                    await HiveDbHelper.saveFoodItem(updatedItem);
                    await NotificationService().cancelNotification(int.parse(item.id) % 100000);
                    final newDays = updatedItem.daysLeft;
                    final expiryDate = DateTime.now().add(Duration(days: newDays));
                    await NotificationService().scheduleExpiryNotification(
                      id: int.parse(item.id) % 100000,
                      itemName: updatedItem.name,
                      expiryDate: expiryDate,
                      daysBeforeExpiry: newDays > 2 ? 2 : 1,
                    );
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(LocalizationService.get(lang, 'updated_success', args: {'name': updatedItem.name})),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.save, color: Colors.white),
                  label: Text(
                    LocalizationService.get(lang, 'save_changes_btn'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _deleteItem(item, lang);
                  },
                  icon: const Icon(LucideIcons.trash2, color: Colors.red),
                  label: Text(
                    LocalizationService.get(lang, 'delete_btn'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

  Color _statusColor(int daysLeft) {
    if (daysLeft <= 1) return Colors.red;
    if (daysLeft <= 3) return Colors.amber;
    return Colors.green;
  }

  String _statusLabel(int daysLeft, String lang) {
    if (daysLeft <= 1) return lang == 'ar' ? 'حرجة!' : (lang == 'en' ? 'Critical!' : 'Kritis!');
    if (daysLeft <= 3) return lang == 'ar' ? 'قريباً' : (lang == 'en' ? 'Soon' : 'Segera');
    return lang == 'ar' ? 'آمنة' : (lang == 'en' ? 'Safe' : 'Aman');
  }

  void _showAddItemSheet(String lang) {
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
                Text(
                  LocalizationService.get(lang, 'add_food_title'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Pilih emoji
                Text(
                  LocalizationService.get(lang, 'choose_icon'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
                  decoration: InputDecoration(
                    labelText: LocalizationService.get(lang, 'food_name_label'),
                    prefixIcon: const Icon(LucideIcons.utensils),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: LocalizationService.get(lang, 'category_label'),
                    prefixIcon: const Icon(LucideIcons.folder),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LocalizationService.get(lang, 'days_before_expiry'),
                    prefixIcon: const Icon(LucideIcons.calendar),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: LocalizationService.get(lang, 'weight_label'),
                          prefixIcon: const Icon(LucideIcons.scale),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: LocalizationService.get(lang, 'price_label'),
                          prefixIcon: const Icon(LucideIcons.wallet),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _saveFoodItem(lang),
                  icon: const Icon(LucideIcons.save, color: Colors.white),
                  label: Text(
                    LocalizationService.get(lang, 'save_btn'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
    final settingsProvider = Provider.of<AppSettingsProvider>(context);
    final lang = settingsProvider.currentLanguage;

    return ValueListenableBuilder(
      valueListenable: HiveDbHelper.foodBoxListenable,
      builder: (context, Box box, _) {
        final items = HiveDbHelper.getFoodItems();
        items.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

        final criticalCount = items.where((i) => i.daysLeft <= 1).length;
        final approachingCount =
            items.where((i) => i.daysLeft > 1 && i.daysLeft <= 3).length;

        // Apply active filter
        List<FoodItem> filtered;
        switch (_activeFilter) {
          case 'kritis':
            filtered = items.where((i) => i.daysLeft <= 1).toList();
            break;
          case 'mendekati':
            filtered =
                items.where((i) => i.daysLeft > 1 && i.daysLeft <= 3).toList();
            break;
          case 'aman':
            filtered = items.where((i) => i.daysLeft > 3).toList();
            break;
          default:
            filtered = items;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              LocalizationService.get(lang, 'tracker_title'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
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
                      const Icon(LucideIcons.alertTriangle,
                          color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizationService.get(lang, 'critical_banner', args: {'count': criticalCount.toString()}),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              LocalizationService.get(lang, 'critical_banner_desc'),
                              style: const TextStyle(
                                  color: Color(0xBFFFFFFF), fontSize: 12),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip(
                        'semua', LocalizationService.get(lang, 'filter_all', args: {'count': items.length.toString()}), Colors.green),
                    _buildFilterChip(
                        'kritis', LocalizationService.get(lang, 'filter_critical', args: {'count': criticalCount.toString()}), Colors.red),
                    _buildFilterChip('mendekati',
                        LocalizationService.get(lang, 'filter_soon', args: {'count': approachingCount.toString()}), Colors.amber),
                    _buildFilterChip('aman', LocalizationService.get(lang, 'filter_safe'), Colors.blue),
                  ],
                ),
              ),

              // List bahan
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(lang)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _buildFoodCard(filtered[i], lang),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddItemSheet(lang),
            backgroundColor: Colors.green,
            icon: const Icon(LucideIcons.plus, color: Colors.white),
            label: Text(
              LocalizationService.get(lang, 'add_ingredient'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
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
          color: isActive ? color : color.withValues(alpha: 0.1),
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

  Widget _buildFoodCard(FoodItem item, String lang) {
    final color = _statusColor(item.daysLeft);
    final label = _statusLabel(item.daysLeft, lang);

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
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(LocalizationService.get(lang, 'confirm_delete_title')),
                content: Text(LocalizationService.get(lang, 'confirm_delete_desc', args: {'name': item.name})),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(LocalizationService.get(lang, 'cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      lang == 'ar' ? 'حذف' : (lang == 'en' ? 'Delete' : 'Hapus'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _deleteItem(item, lang),
      child: GestureDetector(
        onTap: () => _showItemActionSheet(item, lang),
        onLongPress: () => _showEditItemSheet(item, lang),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                  color: color.withValues(alpha: 0.1),
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
                    LocalizationService.get(lang, 'days_left', args: {'count': item.daysLeft.toString()}),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showEditItemSheet(item, lang),
                    child: Icon(LucideIcons.pencil, size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🥗', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            _activeFilter == 'semua'
                ? LocalizationService.get(lang, 'empty_tracker_title')
                : LocalizationService.get(lang, 'empty_filter_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationService.get(lang, 'empty_tracker_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
