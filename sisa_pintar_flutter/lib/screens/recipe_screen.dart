import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../database/hive_db_helper.dart';
import '../models/food_item.dart';
import '../services/groq_api_service.dart';

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

class _RecipeScreenState extends State<RecipeScreen> {

  final List<String> _selectedIngredients = [];
  final List<String> _customIngredients = [];
  final TextEditingController _customController = TextEditingController();

  bool _isLoading = false;
  String _generatedRecipe = '';

  void _toggleSelectIngredient(String name) {
    setState(() {
      if (_selectedIngredients.includes(name)) {
        _selectedIngredients.remove(name);
      } else {
        _selectedIngredients.add(name);
      }
    });
  }

  void _addCustomIngredient() {
    final text = _customController.text.trim();
    if (text.isNotEmpty && !_customIngredients.contains(text)) {
      setState(() {
        _customIngredients.add(text);
        _customController.clear();
      });
    }
  }

  void _removeCustomIngredient(String name) {
    setState(() {
      _customIngredients.remove(name);
    });
  }

  Future<void> _fetchAiRecipe() async {
    final allSelected = [..._selectedIngredients, ..._customIngredients];
    if (allSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 bahan sisa kulkas Anda!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedRecipe = '';
    });

    final recipe = await GroqApiService.generateRecipes(ingredients: allSelected);

    setState(() {
      _generatedRecipe = recipe;
      _isLoading = false;
    });

    // Show details bottom drawer
    _showRecipeDetailsDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final List<FoodItem> trackerItems = HiveDbHelper.getFoodItems();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Recipe AI ✦', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? LucideIcons.sun : LucideIcons.moon),
            onPressed: widget.onToggleDarkMode,
          ),
          IconButton(
            icon: const Icon(LucideIcons.info),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 12),
                  const Text('Apa sisa bahan di kulkasmu?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Pilih bahan kulkas atau tambah bahan lain, biarkan AI mencari resep sehat!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ingredient checklist picker
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pilih Bahan Kulkas Anda:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: trackerItems.map((item) {
                              final isSelected = _selectedIngredients.includes(item.name);
                              return FilterChip(
                                label: Text('${item.emoji} ${item.name}'),
                                selected: isSelected,
                                selectedColor: Colors.green.withOpacity(0.2),
                                checkmarkColor: Colors.green,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                onSelected: (_) => _toggleSelectIngredient(item.name),
                              );
                            }).toList(),
                          ),
                          const Divider(height: 24),
                          
                          // Custom additions chips
                          if (_customIngredients.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              children: _customIngredients.map((name) => Chip(
                                label: Text(name),
                                onDeleted: () => _removeCustomIngredient(name),
                                backgroundColor: Colors.green.shade50,
                              )).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Input custom ingredients
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customController,
                                  decoration: const InputDecoration(
                                    hintText: 'Tambahkan bahan lain...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                  onSubmitted: (_) => _addCustomIngredient(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addCustomIngredient,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade100,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Icon(LucideIcons.plus, color: Colors.black54),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // CTA Search Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchAiRecipe,
                    icon: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.sparkles, color: Colors.white),
                    label: Text(
                      _isLoading ? 'Menganalisis Bahan...' : 'Cari Resep AI ✦', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showRecipeDetailsDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(LucideIcons.chefHat, color: Colors.green),
                SizedBox(width: 8),
                Text('Rekomendasi Resep AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.05)),
                  ),
                  child: Text(
                    _generatedRecipe,
                    style: const TextStyle(fontSize: 13, height: 1.5, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Trigger success confetti screen / consume items
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selamat! Masakan Selesai! Bahan makanan dikonsumsi. 🌿')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Selesai Memasak! 🍳', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

extension on List {
  bool includes(Object? value) => contains(value);
}
