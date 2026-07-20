import '../../domain/entities/branch_entity.dart';

class BranchModel extends BranchEntity {
  const BranchModel({
    required super.id,
    required super.name,
    required super.type,
    required super.location,
    required super.isActive,
    required super.createdAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'Clinic',
      location: (json['address'] as String?) ?? (json['location'] as String?) ?? 'Unknown Location',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': location,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
