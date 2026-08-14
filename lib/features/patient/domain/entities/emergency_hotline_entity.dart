class EmergencyHotlineEntity {
  final String id;
  final String title;
  final String subtitle;
  final String phoneNumber;
  final String iconName;
  final String colorHex;
  final int sortOrder;

  EmergencyHotlineEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.phoneNumber,
    required this.iconName,
    required this.colorHex,
    required this.sortOrder,
  });

  factory EmergencyHotlineEntity.fromJson(Map<String, dynamic> json) {
    return EmergencyHotlineEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      phoneNumber: json['phone_number'] as String,
      iconName: json['icon_name'] as String? ?? 'phone_in_talk',
      colorHex: json['color_hex'] as String? ?? '#4A8D8B',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
