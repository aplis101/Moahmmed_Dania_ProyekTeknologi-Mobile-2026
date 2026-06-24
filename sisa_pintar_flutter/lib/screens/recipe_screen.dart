import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/hive_db_helper.dart';
import '../models/food_item.dart';
import '../models/history_event.dart';
import '../services/groq_api_service.dart';
import '../services/notification_service.dart';

class RecipeScreen extends StatefulWidget {
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;

  const RecipeScreen({
    super.key,
    required this.onToggleDarkMode,
    required this.isDarkMode,
  });

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> with TickerProviderStateMixin {
  final List<String> _selectedIngredients = [];
  final List<String> _customIngredients = [];
  final TextEditingController _customController = TextEditingController();

  bool _isLoading = false;
  String _generatedRecipe = '';

  late AnimationController _loadingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pulseController.dispose();
    _customController.dispose();
    super.dispose();
  }

  void _toggleSelectIngredient(String name) {
    setState(() {
      if (_selectedIngredients.contains(name)) {
        _selectedIngredients.remove(name);
      } else {
        _selectedIngredients.add(name);
      }
    });
  }

  void _selectAllExpiring(List<FoodItem> items) {
    final expiringNames = items.where((i) => i.daysLeft <= 3).map((i) => i.name).toList();
    setState(() {
      for (final name in expiringNames) {
        if (!_selectedIngredients.contains(name)) {
          _selectedIngredients.add(name);
        }
      }
    });
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${expiringNames.length} bahan kritis dipilih!'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addCustomIngredient() {
    final text = _customController.text.trim();
    if (text.isNotEmpty && !_customIngredients.contains(text)) {
      setState(() {
        _customIngredients.add(text);
        _customController.clear();
      });
      HapticFeedback.selectionClick();
    }
  }

  void _removeCustomIngredient(String name) {
    setState(() => _customIngredients.remove(name));
  }

  Future<void> _fetchAiRecipe() async {
    final allSelected = [..._selectedIngredients, ..._customIngredients];
    if (allSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih minimal 1 bahan sisa kulkas Anda!'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _generatedRecipe = '';
    });

    final recipe = await GroqApiService.generateRecipes(ingredients: allSelected);

    setState(() {
      _generatedRecipe = recipe;
      _isLoading = false;
    });

    HapticFeedback.vibrate();
    _showRecipeDetailsDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final List<FoodItem> trackerItems = HiveDbHelper.getFoodItems();
    // Sort: expiring first
    trackerItems.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final expiringCount = trackerItems.where((i) => i.daysLeft <= 3).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar with hero banner
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    widget.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                    key: ValueKey(widget.isDarkMode),
                    color: Colors.white,
                  ),
                ),
                onPressed: widget.onToggleDarkMode,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Smart Recipe AI ✦',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.sparkles, color: Colors.amber, size: 12),
                            SizedBox(width: 4),
                            Text('Powered by Groq Llama3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pilih bahan, biarkan AI memasak untukmu!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ingredient picker card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text('🥗 Pilih Bahan Kulkas:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              if (expiringCount > 0)
                                TextButton.icon(
                                  onPressed: () => _selectAllExpiring(trackerItems),
                                  icon: const Icon(LucideIcons.alertTriangle, size: 14, color: Colors.orange),
                                  label: Text(
                                    'Pilih $expiringCount kritis',
                                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    backgroundColor: Colors.orange.shade50,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (trackerItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Text('🥗', style: TextStyle(fontSize: 40)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Belum ada bahan di tracker.\nTambah dulu di tab Tracker!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: trackerItems.map((item) {
                                final isSelected = _selectedIngredients.contains(item.name);
                                final isExpiring = item.daysLeft <= 3;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: FilterChip(
                                    label: Text(
                                      '${item.emoji} ${item.name}${isExpiring ? ' ⚠️' : ''}',
                                    ),
                                    selected: isSelected,
                                    selectedColor: Colors.green.shade100,
                                    checkmarkColor: Colors.green.shade800,
                                    backgroundColor: isExpiring ? Colors.orange.shade50 : null,
                                    side: BorderSide(
                                      color: isSelected ? Colors.green : (isExpiring ? Colors.orange.shade300 : Colors.grey.shade300),
                                    ),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                    onSelected: (_) {
                                      _toggleSelectIngredient(item.name);
                                      HapticFeedback.selectionClick();
                                    },
                                  ),
                                );
                              }).toList(),
                            ),

                          const Divider(height: 24),

                          // Custom chips
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _customIngredients.isNotEmpty
                                ? Column(
                                    key: const ValueKey('chips'),
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Tambahan:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        children: _customIngredients
                                            .map((name) => Chip(
                                                  label: Text(name, style: const TextStyle(fontSize: 12)),
                                                  onDeleted: () => _removeCustomIngredient(name),
                                                  backgroundColor: Colors.green.shade50,
                                                  deleteIconColor: Colors.green.shade700,
                                                ))
                                            .toList(),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  )
                                : const SizedBox(key: ValueKey('empty')),
                          ),

                          // Custom input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customController,
                                  decoration: InputDecoration(
                                    hintText: 'Tambahkan bahan lain...',
                                    hintStyle: const TextStyle(fontSize: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                  onSubmitted: (_) => _addCustomIngredient(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: _addCustomIngredient,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    child: Icon(LucideIcons.plus, color: Colors.green.shade700, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected count
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: (_selectedIngredients.length + _customIngredients.length) > 0
                        ? Container(
                            key: const ValueKey('count'),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.checkCircle, color: Colors.green.shade700, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedIngredients.length + _customIngredients.length} bahan dipilih',
                                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _selectedIngredients.clear();
                                    _customIngredients.clear();
                                  }),
                                  child: const Text('Hapus semua', style: TextStyle(fontSize: 11, color: Colors.red)),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(key: ValueKey('empty_count')),
                  ),
                  const SizedBox(height: 12),

                  // CTA Button
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) => Transform.scale(
                      scale: _isLoading ? 1.0 : _pulseController.value,
                      child: child,
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fetchAiRecipe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        disabledBackgroundColor: Colors.green.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: _isLoading ? 0 : 4,
                      ),
                      child: _isLoading
                          ? _buildLoadingState()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(LucideIcons.sparkles, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Cari Resep AI ✦',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _loadingController,
          child: const Icon(LucideIcons.sparkles, color: Colors.amber, size: 18),
        ),
        const SizedBox(width: 8),
        const Text(
          'AI sedang menganalisis bahan...',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  void _showRecipeDetailsDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.chefHat, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Rekomendasi Resep AI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  // Copy button
                  IconButton(
                    icon: const Icon(LucideIcons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedRecipe));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text('📋 Resep disalin!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Salin resep',
                  ),
                  // Share button
                  IconButton(
                    icon: const Icon(LucideIcons.share2, size: 18),
                    onPressed: () {
                      // Share functionality
                      Clipboard.setData(ClipboardData(text: _generatedRecipe));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text('📤 Resep siap dibagikan! (disalin ke clipboard)'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    tooltip: 'Bagikan resep',
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            // Recipe content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.08)),
                  ),
                  child: SelectableText(
                    _generatedRecipe,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        HapticFeedback.vibrate();

                        // Actually consume selected food items from DB
                        final allItems = HiveDbHelper.getFoodItems();
                        int consumedCount = 0;
                        int savedMoney = 0;

                        for (final selectedName in _selectedIngredients) {
                          // Find item in DB
                          final matchIndex = allItems.indexWhere((item) => item.name == selectedName);
                          if (matchIndex != -1) {
                            final item = allItems[matchIndex];
                            
                            // Save to history
                            final event = HistoryEvent(
                              id: '${DateTime.now().millisecondsSinceEpoch}_$consumedCount',
                              name: item.name,
                              emoji: item.emoji,
                              weight: item.weight,
                              price: item.price,
                              action: 'consumed',
                              timestamp: DateTime.now().millisecondsSinceEpoch,
                            );
                            await HiveDbHelper.saveHistoryEvent(event);
                            
                            // Delete from tracker
                            await HiveDbHelper.deleteFoodItem(item.id);
                            await NotificationService().cancelNotification(int.parse(item.id) % 100000);
                            
                            savedMoney += item.price;
                            consumedCount++;
                          }
                        }

                        // Clear selected lists
                        setState(() {
                          _selectedIngredients.clear();
                          _customIngredients.clear();
                        });

                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(consumedCount > 0
                                      ? 'Masakan selesai! $consumedCount bahan dikonsumsi & diselamatkan (Rp $savedMoney)!'
                                      : 'Masakan selesai! Bahan tambahan dikonsumsi. 🌿'),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.chefHat, color: Colors.white, size: 18),
                      label: const Text('Selesai Memasak! 🍳',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
