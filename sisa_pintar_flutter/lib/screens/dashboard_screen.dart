import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../database/hive_db_helper.dart';
import '../models/history_event.dart';
import '../services/localization_service.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;

  const DashboardScreen({
    super.key,
    required this.onToggleDarkMode,
    required this.isDarkMode,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activePeriodIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<AppSettingsProvider>(context);
    final lang = settingsProvider.currentLanguage;

    final periods = [
      LocalizationService.get(lang, 'period_week'),
      LocalizationService.get(lang, 'period_month'),
      LocalizationService.get(lang, 'period_all'),
    ];

    final List<HistoryEvent> history = HiveDbHelper.getHistoryEvents();
    final consumedItems = history.where((h) => h.action == 'consumed').toList();
    final wastedItems = history.where((h) => h.action == 'wasted').toList();

    final totalSavedWeight = consumedItems.fold<double>(0, (sum, item) => sum + item.weight);
    final totalWastedWeight = wastedItems.fold<double>(0, (sum, item) => sum + item.weight);
    final totalWeightCombined = totalSavedWeight + totalWastedWeight;

    final totalSavedMoney = consumedItems.fold<int>(0, (sum, item) => sum + item.price);
    final recipesCookedCount = consumedItems.length + 3;

    final double savedPercent = totalWeightCombined > 0 
        ? (totalSavedWeight / totalWeightCombined) * 100 
        : 100;
    final double wastedPercent = 100 - savedPercent;

    final kgLeft = (15 - totalSavedWeight).isNegative ? '0.0' : (15 - totalSavedWeight).toStringAsFixed(1);
    final nextLevelText = LocalizationService.get(lang, 'next_level', args: {'kg': kgLeft});

    final days = lang == 'ar'
        ? ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']
        : (lang == 'en'
            ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            : ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']);

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.get(lang, 'dashboard_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? LucideIcons.sun : LucideIcons.moon),
            onPressed: widget.onToggleDarkMode,
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Selector
              Row(
                children: periods.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final isActive = _activePeriodIndex == idx;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isActive,
                      selectedColor: Colors.green,
                      labelStyle: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _activePeriodIndex = idx;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Hero Stats Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          LocalizationService.get(lang, 'eco_level'),
                          style: const TextStyle(color: Color(0xFFE8F5E9), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${totalSavedWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
                    ),
                    Text(
                      LocalizationService.get(lang, 'saved_desc'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.7,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(nextLevelText, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.white24, height: 1),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rp ${totalSavedMoney.toString()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(LocalizationService.get(lang, 'total_saved_money'), style: const TextStyle(color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$recipesCookedCount Resep', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(LocalizationService.get(lang, 'cooked_count'), style: const TextStyle(color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pie Chart Composition Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LocalizationService.get(lang, 'composition_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 28,
                                sections: [
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: savedPercent,
                                    title: '',
                                    radius: 12,
                                  ),
                                  PieChartSectionData(
                                    color: Colors.red,
                                    value: wastedPercent,
                                    title: '',
                                    radius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildLegendItem(LocalizationService.get(lang, 'saved'), savedPercent, Colors.green),
                                const SizedBox(height: 8),
                                _buildLegendItem(LocalizationService.get(lang, 'wasted'), wastedPercent, Colors.red),
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weekly Progress Bar Chart
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LocalizationService.get(lang, 'weekly_progress'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 110,
                        child: BarChart(
                          BarChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              _buildBarGroup(0, 1.2, Colors.green),
                              _buildBarGroup(1, 0.8, Colors.green.shade300),
                              _buildBarGroup(2, 1.5, Colors.green),
                              _buildBarGroup(3, 0.9, Colors.green.shade300),
                              _buildBarGroup(4, 1.4, Colors.green),
                              _buildBarGroup(5, 0.8, Colors.green.shade300),
                              _buildBarGroup(6, 0.5, Colors.green.shade300),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Badges Section
              Text(LocalizationService.get(lang, 'achievements'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildBadgeCard('🌱', LocalizationService.get(lang, 'badge_first_save_title'), LocalizationService.get(lang, 'badge_first_save_desc'), Colors.amber.shade50),
                    _buildBadgeCard('🍳', LocalizationService.get(lang, 'badge_chef_title'), LocalizationService.get(lang, 'badge_chef_desc'), Colors.purple.shade50),
                    _buildBadgeCard('🏆', LocalizationService.get(lang, 'badge_zero_waste_title'), LocalizationService.get(lang, 'badge_zero_waste_desc'), Colors.green.shade50),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double val, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Text('${val.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 14,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        )
      ],
    );
  }

  Widget _buildBadgeCard(String emoji, String title, String desc, Color bg) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 20,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Expanded(
            child: Text(desc, style: const TextStyle(fontSize: 8, color: Colors.grey, height: 1.3), textAlign: TextAlign.center),
          )
        ],
      ),
    );
  }
}
