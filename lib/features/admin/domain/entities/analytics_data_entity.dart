class AnalyticsDataEntity {
  final KPIMetrics kpiMetrics;
  final List<RevenuePoint> revenueData;
  final List<AppointmentTrendPoint> appointmentTrends;
  final List<AppointmentStatusPoint> appointmentStatus;
  final List<DepartmentPoint> departmentData;
  final List<DoctorPerformancePoint> topDoctors;
  final List<DemographicPoint> patientDemographics;
  final List<QueueMetricPoint> queueMetrics;

  const AnalyticsDataEntity({
    required this.kpiMetrics,
    required this.revenueData,
    required this.appointmentTrends,
    required this.appointmentStatus,
    required this.departmentData,
    required this.topDoctors,
    required this.patientDemographics,
    required this.queueMetrics,
  });
}

class KPIMetrics {
  final int totalAppointments;
  final int totalPatients;
  final double totalRevenue;
  final double avgConsultationDuration;
  final int availableDoctors;
  final double appointmentCompletionRate;

  const KPIMetrics({
    required this.totalAppointments,
    required this.totalPatients,
    required this.totalRevenue,
    required this.avgConsultationDuration,
    required this.availableDoctors,
    required this.appointmentCompletionRate,
  });
}

class RevenuePoint {
  final String label;
  final double value;

  const RevenuePoint({required this.label, required this.value});
}

class AppointmentTrendPoint {
  final String date;
  final int count;

  const AppointmentTrendPoint({required this.date, required this.count});
}

class AppointmentStatusPoint {
  final String status;
  final int count;

  const AppointmentStatusPoint({required this.status, required this.count});
}

class DepartmentPoint {
  final String department;
  final int count;

  const DepartmentPoint({required this.department, required this.count});
}

class DoctorPerformancePoint {
  final String name;
  final int appointmentCount;
  final double rating;

  const DoctorPerformancePoint({
    required this.name,
    required this.appointmentCount,
    required this.rating,
  });
}

class DemographicPoint {
  final String category;
  final int count;

  const DemographicPoint({required this.category, required this.count});
}

class QueueMetricPoint {
  final String department;
  final double avgWaitTime;
  final int patientsWaiting;

  const QueueMetricPoint({
    required this.department,
    required this.avgWaitTime,
    required this.patientsWaiting,
  });
}
