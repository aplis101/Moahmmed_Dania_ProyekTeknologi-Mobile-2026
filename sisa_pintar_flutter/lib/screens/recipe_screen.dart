import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../database/hive_db_helper.dart';
import '../models/food_item.dart';
import '../models/history_event.dart';
import '../services/groq_api_service.dart';
import '../services/notification_service.dart';
import '../services/localization_service.dart';
import '../main.dart';

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

class _RecipeScreenState extends State<RecipeScreen>
    with TickerProviderStateMixin {
  final List<String> _selectedIngredients = [];
  final List<String> _customIngredients = [];
  final TextEditingController _customController = TextEditingController();

  bool _isLoading = false;
  String _generatedRecipe = '';

  // Saved recipes: list of {title, content}
  final List<Map<String, String>> _savedRecipes = [];
  bool _justSaved = false;

  late AnimationController _loadingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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

  void _selectAllExpiring(List<FoodItem> items, String lang) {
    final expiringNames = items
        .where((i) => i.daysLeft <= 3)
        .map((i) => i.name)
        .toList();
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
        content: Text(LocalizationService.get(lang, 'choose_critical', args: {'count': expiringNames.length.toString()})),
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

  Future<void> _fetchAiRecipe(String lang) async {
    final allSelected = [..._selectedIngredients, ..._customIngredients];
    if (allSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.get(lang, 'select_at_least_one')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _generatedRecipe = '';
    });

    final recipe = await GroqApiService.generateRecipes(
      ingredients: allSelected,
      language: lang == 'ar' ? 'Arabic' : (lang == 'en' ? 'English' : 'Indonesian'),
    );

    setState(() {
      _generatedRecipe = recipe;
      _isLoading = false;
      _justSaved = false;
    });

    HapticFeedback.vibrate();
    _showRecipeDetailsDrawer(lang);
  }

  /// Extract a short title from the recipe text (first meaningful line, max 28 chars)
  String _extractTitle(String recipe) {
    final lines = recipe.split('\n');
    for (final line in lines) {
      final cleaned = line
          .replaceAll('**', '')
          .replaceAll('*', '')
          .replaceAll('#', '')
          .replaceAll('🍳', '')
          .replaceAll('🍽️', '')
          .trim();
      if (cleaned.isNotEmpty && cleaned.length > 3) {
        return cleaned.length > 28 ? '${cleaned.substring(0, 28)}…' : cleaned;
      }
    }
    return 'Recipe ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
  }

  void _saveCurrentRecipe() {
    if (_generatedRecipe.isEmpty) return;
    final title = _extractTitle(_generatedRecipe);
    setState(() {
      _savedRecipes.insert(0, {
        'title': title,
        'content': _generatedRecipe,
      });
      _justSaved = true;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<AppSettingsProvider>(context);
    final lang = settingsProvider.currentLanguage;

    final List<FoodItem> trackerItems = HiveDbHelper.getFoodItems();
    trackerItems.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final expiringCount = trackerItems.where((i) => i.daysLeft <= 3).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar
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
              title: Text(
                LocalizationService.get(lang, 'recipe_ai_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                bottom: 16,
              ),
              centerTitle: false,
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              LucideIcons.sparkles,
                              color: Colors.amber,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Powered by Groq Llama3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LocalizationService.get(lang, 'recipe_ai_subtitle'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                  // ─── Ingredient picker card ───
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  LocalizationService.get(lang, 'choose_ingredients'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (expiringCount > 0)
                                TextButton.icon(
                                  onPressed: () =>
                                      _selectAllExpiring(trackerItems, lang),
                                  icon: const Icon(
                                    LucideIcons.alertTriangle,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                  label: Text(
                                    LocalizationService.get(lang, 'choose_critical', args: {'count': expiringCount.toString()}),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    backgroundColor: Colors.orange.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (trackerItems.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      '🥗',
                                      style: TextStyle(fontSize: 40),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      LocalizationService.get(lang, 'no_ingredients_tracker'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13,
                                      ),
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
                                final isSelected =
                                    _selectedIngredients.contains(item.name);
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
                                    backgroundColor: isExpiring
                                        ? Colors.orange.shade50
                                        : null,
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.green
                                          : (isExpiring
                                              ? Colors.orange.shade300
                                              : Colors.grey.shade300),
                                    ),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.green.shade800
                                          : Colors.grey.shade700,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LocalizationService.get(lang, 'add_more'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        children: _customIngredients
                                            .map(
                                              (name) => Chip(
                                                label: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                onDeleted: () =>
                                                    _removeCustomIngredient(
                                                        name),
                                                backgroundColor:
                                                    Colors.green.shade50,
                                                deleteIconColor:
                                                    Colors.green.shade700,
                                              ),
                                            )
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
                                    hintText: LocalizationService.get(lang, 'add_custom_hint'),
                                    hintStyle:
                                        const TextStyle(fontSize: 13),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
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
                                    child: Icon(
                                      LucideIcons.plus,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
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
                    child:
                        (_selectedIngredients.length +
                                    _customIngredients.length) >
                                0
                            ? Container(
                                key: const ValueKey('count'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.checkCircle,
                                      color: Colors.green.shade700,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      LocalizationService.get(lang, 'ingredients_selected', args: {'count': (_selectedIngredients.length + _customIngredients.length).toString()}),
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _selectedIngredients.clear();
                                        _customIngredients.clear();
                                      }),
                                      child: Text(
                                        LocalizationService.get(lang, 'clear_all'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(
                                key: ValueKey('empty_count')),
                  ),
                  const SizedBox(height: 12),

                  // CTA Button
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _isLoading
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF81C784),
                                    Color(0xFF4CAF50),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment(
                                      -2.0 +
                                          4.0 * _pulseController.value,
                                      -1.0),
                                  end: Alignment(
                                      -1.0 +
                                          4.0 * _pulseController.value,
                                      1.0),
                                  colors: const [
                                    Color(0xFF1B5E20),
                                    Color(0xFF4CAF50),
                                    Color(0xFF1B5E20),
                                  ],
                                  stops: const [0.3, 0.5, 0.7],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _fetchAiRecipe(lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledForegroundColor: Colors.white70,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? _buildLoadingState(lang)
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.sparkles,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  LocalizationService.get(lang, 'search_recipe_btn'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Saved Recipes Section ───
                  if (_savedRecipes.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          '📌',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            LocalizationService.get(lang, 'saved_recipes_title'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          LocalizationService.get(lang, 'recipes_count', args: {'count': _savedRecipes.length.toString()}),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._savedRecipes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final recipe = entry.value;
                      return _buildSavedRecipeCard(idx, recipe, lang);
                    }),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRecipeCard(int index, Map<String, String> recipe, String lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child:
                Text('📖', style: TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(
          recipe['title'] ?? 'Recipe ${index + 1}',
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          LocalizationService.get(lang, 'tap_to_view'),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
        trailing: IconButton(
          icon: Icon(LucideIcons.trash2,
              size: 16, color: Colors.red.shade300),
          onPressed: () {
            setState(() => _savedRecipes.removeAt(index));
          },
        ),
        onTap: () {
          setState(() {
            _generatedRecipe = recipe['content'] ?? '';
            _justSaved = true;
          });
          _showRecipeDetailsDrawer(lang);
        },
      ),
    );
  }

  Widget _buildLoadingState(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _loadingController,
          child: const Icon(
            LucideIcons.sparkles,
            color: Colors.amber,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          LocalizationService.get(lang, 'ai_analyzing'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Build a rich emoji-enhanced recipe display widget
  Widget _buildRichRecipeContent(String recipe) {
    final lines = recipe.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 6);

        final isBold = trimmed.startsWith('**') && trimmed.endsWith('**');
        final isSectionHeader = isBold ||
            trimmed.startsWith('🍳') ||
            trimmed.startsWith('🍽️') ||
            trimmed.startsWith('⏱') ||
            trimmed.startsWith('🥗') ||
            trimmed.startsWith('👨‍🍳') ||
            trimmed.startsWith('💡') ||
            trimmed.startsWith('🌱') ||
            trimmed.startsWith('⚠️');

        final displayText = trimmed
            .replaceAll('**', '')
            .replaceAll('*', '');

        if (isSectionHeader) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.15)),
              ),
              child: Text(
                displayText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          );
        }

        final isStep = RegExp(r'^[\d️⃣1-9]').hasMatch(trimmed);
        if (isStep) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    displayText,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }

        if (trimmed.startsWith('-') ||
            trimmed.startsWith('•') ||
            trimmed.startsWith('·')) {
          return Padding(
            padding:
                const EdgeInsets.only(top: 2, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                Expanded(
                  child: Text(
                    displayText.replaceFirst(RegExp(r'^[-•·]\s*'), ''),
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            displayText,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showRecipeDetailsDrawer(String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.chefHat,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LocalizationService.get(lang, 'ai_recommendation'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    // Copy button
                    IconButton(
                      icon: const Icon(LucideIcons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _generatedRecipe));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(LocalizationService.get(lang, 'recipe_copied')),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Copy recipe',
                    ),
                    // Share button
                    IconButton(
                      icon: const Icon(LucideIcons.share2, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _generatedRecipe));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(LocalizationService.get(lang, 'recipe_copied')),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      tooltip: 'Share recipe',
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
                      color:
                          Colors.green.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.08),
                      ),
                    ),
                    child: _buildRichRecipeContent(_generatedRecipe),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Save Recipe Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _justSaved
                            ? null
                            : () {
                                _saveCurrentRecipe();
                                setSheetState(() {});
                              },
                        icon: Icon(
                          _justSaved
                              ? LucideIcons.checkCircle
                              : LucideIcons.bookmark,
                          size: 17,
                          color: _justSaved
                              ? Colors.green
                              : Colors.green.shade700,
                        ),
                        label: Text(
                          _justSaved
                              ? LocalizationService.get(lang, 'just_saved')
                              : LocalizationService.get(lang, 'save_recipe'),
                          style: TextStyle(
                            color: _justSaved
                                ? Colors.green
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          side: BorderSide(
                            color: _justSaved
                                ? Colors.green
                                : Colors.green.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (_justSaved)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '📌 "${_extractTitle(_generatedRecipe)}"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(LocalizationService.get(lang, 'cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger =
                              ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          HapticFeedback.vibrate();

                          final allItems = HiveDbHelper.getFoodItems();
                          int consumedCount = 0;
                          int savedMoney = 0;

                          for (final selectedName
                              in _selectedIngredients) {
                            final matchIndex = allItems.indexWhere(
                              (item) => item.name == selectedName,
                            );
                            if (matchIndex != -1) {
                              final item = allItems[matchIndex];
                              final event = HistoryEvent(
                                id: '${DateTime.now().millisecondsSinceEpoch}_$consumedCount',
                                name: item.name,
                                emoji: item.emoji,
                                weight: item.weight,
                                price: item.price,
                                action: 'consumed',
                                timestamp: DateTime.now()
                                    .millisecondsSinceEpoch,
                              );
                              await HiveDbHelper.saveHistoryEvent(event);
                              await HiveDbHelper.deleteFoodItem(item.id);
                              await NotificationService()
                                  .cancelNotification(
                                int.parse(item.id) % 100000,
                              );
                              savedMoney += item.price;
                              consumedCount++;
                            }
                          }

                          setState(() {
                            _selectedIngredients.clear();
                            _customIngredients.clear();
                          });

                          messenger.showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Text(
                                    '🎉',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      consumedCount > 0
                                          ? LocalizationService.get(lang, 'cooking_done_snack', args: {
                                              'count': consumedCount.toString(),
                                              'money': savedMoney.toString()
                                            })
                                          : LocalizationService.get(lang, 'cooking_done_custom_snack'),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                        icon: const Icon(
                          LucideIcons.chefHat,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          LocalizationService.get(lang, 'finish_cooking'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
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
