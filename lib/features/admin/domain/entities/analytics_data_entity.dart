class AnalyticsDataEntity {
  final List<RevenuePoint> revenueData;
  final List<DepartmentPoint> departmentData;

  const AnalyticsDataEntity({
    required this.revenueData,
    required this.departmentData,
  });
}

class RevenuePoint {
  final String label;
  final double value;

  const RevenuePoint({required this.label, required this.value});
}

class DepartmentPoint {
  final String department;
  final int count;

  const DepartmentPoint({required this.department, required this.count});
}
