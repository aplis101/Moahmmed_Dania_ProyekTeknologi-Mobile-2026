import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_item.dart';
import '../models/history_event.dart';

class HiveDbHelper {
  static const String foodBoxName = 'food_items_box';
  static const String historyBoxName = 'history_events_box';
  static const String settingsBoxName = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    // Open boxes
    await Hive.openBox(foodBoxName);
    await Hive.openBox(historyBoxName);
    await Hive.openBox(settingsBoxName);

    final foodBox = Hive.box(foodBoxName);
    final historyBox = Hive.box(historyBoxName);

    // Pre-populate with sample data if empty to ensure rich aesthetics on first run
    if (foodBox.isEmpty) {
      final sampleItems = [
        FoodItem(id: '1', emoji: '🥛', name: 'Susu UHT Full Cream', category: 'Minuman', daysLeft: 1, weight: 1.0, price: 18000),
        FoodItem(id: '2', emoji: '🍞', name: 'Roti Tawar Gandum', category: 'Roti', daysLeft: 3, weight: 0.4, price: 15000),
        FoodItem(id: '3', emoji: '🥕', name: 'Wortel Segar', category: 'Sayur', daysLeft: 12, weight: 0.5, price: 8000),
        FoodItem(id: '4', emoji: '🥚', name: 'Telur Ayam Kampung', category: 'Protein', daysLeft: 5, weight: 0.6, price: 22000),
      ];
      for (var item in sampleItems) {
        await foodBox.put(item.id, item.toMap());
      }
    }

    if (historyBox.isEmpty) {
      final sampleEvents = [
        HistoryEvent(id: 'h1', name: 'Bayam Segar', emoji: '🥬', weight: 0.5, price: 5000, action: 'consumed', timestamp: DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch),
        HistoryEvent(id: 'h2', name: 'Nasi Sisa', emoji: '🍚', weight: 0.3, price: 3000, action: 'consumed', timestamp: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
        HistoryEvent(id: 'h3', name: 'Tomat Merah', emoji: '🍅', weight: 0.4, price: 6000, action: 'consumed', timestamp: DateTime.now().millisecondsSinceEpoch),
        HistoryEvent(id: 'h4', name: 'Pisang Matang', emoji: '🍌', weight: 0.6, price: 12000, action: 'consumed', timestamp: DateTime.now().millisecondsSinceEpoch),
        HistoryEvent(id: 'h5', name: 'Roti Manis', emoji: '🍞', weight: 0.2, price: 8000, action: 'wasted', timestamp: DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch),
      ];
      for (var event in sampleEvents) {
        await historyBox.put(event.id, event.toMap());
      }
    }
  }

  // Box references
  static Box get _foodBox => Hive.box(foodBoxName);
  static Box get _historyBox => Hive.box(historyBoxName);
  static Box get _settingsBox => Hive.box(settingsBoxName);

  // ValueListenable for reactive UI updates (fixes UI freeze issue)
  static ValueListenable<Box> get foodBoxListenable =>
      Hive.box(foodBoxName).listenable();
  static ValueListenable<Box> get historyBoxListenable =>
      Hive.box(historyBoxName).listenable();

  // --- Food Items CRUD ---
  static List<FoodItem> getFoodItems() {
    final List<FoodItem> items = [];
    for (var key in _foodBox.keys) {
      final map = _foodBox.get(key);
      if (map != null) {
        items.add(FoodItem.fromMap(Map<dynamic, dynamic>.from(map)));
      }
    }
    return items;
  }

  static Future<void> saveFoodItem(FoodItem item) async {
    await _foodBox.put(item.id, item.toMap());
  }

  static Future<void> deleteFoodItem(String id) async {
    await _foodBox.delete(id);
  }

  // --- History Events CRUD ---
  static List<HistoryEvent> getHistoryEvents() {
    final List<HistoryEvent> events = [];
    for (var key in _historyBox.keys) {
      final map = _historyBox.get(key);
      if (map != null) {
        events.add(HistoryEvent.fromMap(Map<dynamic, dynamic>.from(map)));
      }
    }
    return events;
  }

  static Future<void> saveHistoryEvent(HistoryEvent event) async {
    await _historyBox.put(event.id, event.toMap());
  }

  static Future<void> clearAll() async {
    await _foodBox.clear();
    await _historyBox.clear();
  }

  // --- Settings / API Key / Language ---
  static String getGroqApiKey() {
    return _settingsBox.get('groq_api_key', defaultValue: '') as String;
  }

  static Future<void> saveGroqApiKey(String key) async {
    await _settingsBox.put('groq_api_key', key);
  }

  static String getAppLanguage() {
    return _settingsBox.get('app_language', defaultValue: 'id') as String;
  }

  static Future<void> saveAppLanguage(String lang) async {
    await _settingsBox.put('app_language', lang);
  }

  static bool getDarkTheme() {
    return _settingsBox.get('dark_theme', defaultValue: false) as bool;
  }

  static Future<void> saveDarkTheme(bool isDark) async {
    await _settingsBox.put('dark_theme', isDark);
  }
}
