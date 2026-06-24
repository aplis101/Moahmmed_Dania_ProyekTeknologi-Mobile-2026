class HistoryEvent {
  final String id;
  final String name;
  final String emoji;
  final double weight;
  final int price;
  final String action; // 'consumed' | 'wasted'
  final int timestamp; // epoch ms

  HistoryEvent({
    required this.id,
    required this.name,
    required this.emoji,
    required this.weight,
    required this.price,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'weight': weight,
      'price': price,
      'action': action,
      'timestamp': timestamp,
    };
  }

  factory HistoryEvent.fromMap(Map<dynamic, dynamic> map) {
    return HistoryEvent(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '📦',
      weight: (map['weight'] as num? ?? 0.0).toDouble(),
      price: (map['price'] as num? ?? 0).toInt(),
      action: map['action'] as String? ?? 'consumed',
      timestamp: (map['timestamp'] as num? ?? DateTime.now().millisecondsSinceEpoch).toInt(),
    );
  }
}
