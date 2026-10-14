class WorkOrderItem {
  final String id;
  final String name;
  final String notes;

  const WorkOrderItem({
    required this.id,
    required this.name,
    this.notes = '',
  });

  WorkOrderItem copyWith({String? name, String? notes}) => WorkOrderItem(
        id: id,
        name: name ?? this.name,
        notes: notes ?? this.notes,
      );

  factory WorkOrderItem.fromJson(Map<String, dynamic> json) => WorkOrderItem(
        id: json['id'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'notes': notes};
}
