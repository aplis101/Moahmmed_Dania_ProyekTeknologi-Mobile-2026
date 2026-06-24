class FoodItem {
  final String id;
  final String emoji;
  final String name;
  final String category;
  final int daysLeft;
  final double weight; // in kg
  final int price; // in IDR

  FoodItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.category,
    required this.daysLeft,
    required this.weight,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
      'category': category,
      'daysLeft': daysLeft,
      'weight': weight,
      'price': price,
    };
  }

  factory FoodItem.fromMap(Map<dynamic, dynamic> map) {
    return FoodItem(
      id: map['id'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '📦',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      daysLeft: (map['daysLeft'] as num? ?? 3).toInt(),
      weight: (map['weight'] as num? ?? 0.5).toDouble(),
      price: (map['price'] as num? ?? 0).toInt(),
    );
  }
}
