class BranchEntity {
  final String id;
  final String name;
  final String type;
  final String location;
  final bool isActive;
  final DateTime createdAt;

  const BranchEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.isActive,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
