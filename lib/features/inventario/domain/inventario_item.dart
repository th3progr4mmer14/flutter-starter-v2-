class InventarioItem {
  final String id;
  final String name;
  final String notes;

  const InventarioItem({
    required this.id,
    required this.name,
    this.notes = '',
  });

  InventarioItem copyWith({String? name, String? notes}) => InventarioItem(
        id: id,
        name: name ?? this.name,
        notes: notes ?? this.notes,
      );

  factory InventarioItem.fromJson(Map<String, dynamic> json) => InventarioItem(
        id: json['id'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'notes': notes};
}
