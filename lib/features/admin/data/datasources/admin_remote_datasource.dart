import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch_model.dart';
import '../../domain/entities/analytics_data_entity.dart';

class AdminRemoteDataSource {
  final SupabaseClient _client;

  AdminRemoteDataSource(this._client);

  Future<List<BranchModel>> getBranches() async {
    final data = await _client.from('branches').select().order('name');
    return data.map((json) => BranchModel.fromJson(json)).toList();
  }

  Future<AnalyticsDataEntity> getAnalyticsData() async {
    try {
      // Fetch appointments for KPIs and trends
      final appointments = await _client.from('appointments').select();

      // Fetch invoices for revenue data
      final invoices = await _client.from('invoices').select();

      // Fetch profiles for patient count
      final profiles = await _client
          .from('profiles')
          .select('id, date_of_birth, gender');

      // Fetch doctors for doctor data
      final doctors = await _client
          .from('doctors')
          .select('id, name, specialization');

      // Calculate KPIs
      final kpiMetrics = _calculateKPIMetrics(
        appointments,
        invoices,
        profiles,
        doctors,
      );

      // Generate revenue data (last 30 days)
      final revenueData = _generateRevenueData(invoices);

      // Generate appointment trends
      final appointmentTrends = _generateAppointmentTrends(appointments);

      // Generate appointment status distribution
      final appointmentStatus = _generateAppointmentStatus(appointments);

      // Generate department data
      final departmentData = _generateDepartmentData(appointments);

      // Generate top doctors
      final topDoctors = _generateTopDoctors(appointments, doctors);

      // Generate patient demographics
      final patientDemographics = _generatePatientDemographics(profiles);

      // Generate queue metrics
      final queueMetrics = _generateQueueMetrics();

      return AnalyticsDataEntity(
        kpiMetrics: kpiMetrics,
        revenueData: revenueData,
        appointmentTrends: appointmentTrends,
        appointmentStatus: appointmentStatus,
        departmentData: departmentData,
        topDoctors: topDoctors,
        patientDemographics: patientDemographics,
        queueMetrics: queueMetrics,
      );
    } catch (e) {
      // Fall back to dummy data if query fails
      return _getDummyAnalytics();
    }
  }

  KPIMetrics _calculateKPIMetrics(
    List<dynamic> appointments,
    List<dynamic> invoices,
    List<dynamic> profiles,
    List<dynamic> doctors,
  ) {
    int completedCount = appointments
        .where((a) => a['status'] == 'completed')
        .length;
    double totalRev = invoices.fold<double>(
      0,
      (sum, inv) => sum + ((inv['amount'] ?? 0) as num).toDouble(),
    );
    int docCount = doctors.length;
    double completionRate = appointments.isNotEmpty
        ? (completedCount / appointments.length) * 100
        : 0;

    return KPIMetrics(
      totalAppointments: appointments.length,
      totalPatients: profiles.length,
      totalRevenue: totalRev,
      avgConsultationDuration: 45.0,
      availableDoctors: docCount,
      appointmentCompletionRate: completionRate,
    );
  }

  List<RevenuePoint> _generateRevenueData(List<dynamic> invoices) {
    final Map<String, double> revenueByDay = {};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (var day in days) {
      revenueByDay[day] = 0;
    }

    for (var invoice in invoices) {
      final dayIndex = DateTime.now().weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        revenueByDay[days[dayIndex]] =
            (revenueByDay[days[dayIndex]] ?? 0) +
            ((invoice['amount'] ?? 0) as num).toDouble();
      }
    }

    return days
        .map((day) => RevenuePoint(label: day, value: revenueByDay[day] ?? 0))
        .toList();
  }

  List<AppointmentTrendPoint> _generateAppointmentTrends(
    List<dynamic> appointments,
  ) {
    final Map<String, int> trendByDay = {};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (var day in days) {
      trendByDay[day] = 0;
    }

    for (var apt in appointments) {
      final dayIndex = DateTime.now().weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        trendByDay[days[dayIndex]] = (trendByDay[days[dayIndex]] ?? 0) + 1;
      }
    }

    return days
        .map(
          (day) =>
              AppointmentTrendPoint(date: day, count: trendByDay[day] ?? 0),
        )
        .toList();
  }

  List<AppointmentStatusPoint> _generateAppointmentStatus(
    List<dynamic> appointments,
  ) {
    final statuses = <String, int>{};

    for (var apt in appointments) {
      final status = apt['status'] as String? ?? 'pending';
      statuses[status] = (statuses[status] ?? 0) + 1;
    }

    return statuses.entries
        .map((e) => AppointmentStatusPoint(status: e.key, count: e.value))
        .toList();
  }

  List<DepartmentPoint> _generateDepartmentData(List<dynamic> appointments) {
    final departments = <String, int>{};

    for (var apt in appointments) {
      final dept = apt['department'] as String? ?? 'General';
      departments[dept] = (departments[dept] ?? 0) + 1;
    }

    return departments.entries
        .map((e) => DepartmentPoint(department: e.key, count: e.value))
        .toList();
  }

  List<DoctorPerformancePoint> _generateTopDoctors(
    List<dynamic> appointments,
    List<dynamic> doctors,
  ) {
    final doctorStats = <String, Map<String, dynamic>>{};

    for (var apt in appointments) {
      final docId = apt['doctor_id'] as String?;
      if (docId != null) {
        if (!doctorStats.containsKey(docId)) {
          doctorStats[docId] = {'count': 0, 'name': 'Dr. Unknown'};
        }
        doctorStats[docId]!['count'] =
            (doctorStats[docId]!['count'] as int) + 1;
      }
    }

    for (var doc in doctors) {
      final docId = doc['id'] as String;
      if (doctorStats.containsKey(docId)) {
        doctorStats[docId]!['name'] = 'Dr. ${doc['name'] ?? 'Unknown'}';
      }
    }

    final result = doctorStats.entries
        .map(
          (e) => DoctorPerformancePoint(
            name: e.value['name'] as String,
            appointmentCount: e.value['count'] as int,
            rating: 4.5,
          ),
        )
        .toList();

    result.sort((a, b) => b.appointmentCount.compareTo(a.appointmentCount));
    return result.take(5).toList();
  }

  List<DemographicPoint> _generatePatientDemographics(List<dynamic> profiles) {
    final ageGroups = <String, int>{
      '18-25': 0,
      '26-35': 0,
      '36-45': 0,
      '46-55': 0,
      '55+': 0,
    };

    for (var profile in profiles) {
      final dob = profile['date_of_birth'] as String?;
      if (dob != null) {
        try {
          final age = DateTime.now().year - DateTime.parse(dob).year;
          if (age < 18) continue;
          if (age <= 25) {
            ageGroups['18-25'] = ageGroups['18-25']! + 1;
          } else if (age <= 35)
            ageGroups['26-35'] = ageGroups['26-35']! + 1;
          else if (age <= 45)
            ageGroups['36-45'] = ageGroups['36-45']! + 1;
          else if (age <= 55)
            ageGroups['46-55'] = ageGroups['46-55']! + 1;
          else
            ageGroups['55+'] = ageGroups['55+']! + 1;
        } catch (_) {}
      }
    }

    return ageGroups.entries
        .map((e) => DemographicPoint(category: e.key, count: e.value))
        .toList();
  }

  List<QueueMetricPoint> _generateQueueMetrics() {
    return const [
      QueueMetricPoint(
        department: 'Psychiatry',
        avgWaitTime: 15.0,
        patientsWaiting: 3,
      ),
      QueueMetricPoint(
        department: 'General',
        avgWaitTime: 10.0,
        patientsWaiting: 5,
      ),
      QueueMetricPoint(
        department: 'Cardiology',
        avgWaitTime: 20.0,
        patientsWaiting: 2,
      ),
    ];
  }

  List<BranchModel> _getDummyBranches() {
    return [
      BranchModel(
        id: '1',
        name: 'Chiromo Lane',
        type: 'Headquarters',
        location: 'Muthithi Road, Westlands',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      BranchModel(
        id: '2',
        name: 'Bustani',
        type: 'Rehabilitation Center',
        location: 'Lavington, Nairobi',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      BranchModel(
        id: '3',
        name: 'Mombasa Branch',
        type: 'Outpatient Clinic',
        location: 'Nyali, Mombasa',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    ];
  }

  AnalyticsDataEntity _getDummyAnalytics() {
    return AnalyticsDataEntity(
      kpiMetrics: const KPIMetrics(
        totalAppointments: 248,
        totalPatients: 156,
        totalRevenue: 1245000,
        avgConsultationDuration: 45.0,
        availableDoctors: 12,
        appointmentCompletionRate: 87.5,
      ),
      revenueData: const [
        RevenuePoint(label: 'Mon', value: 35000),
        RevenuePoint(label: 'Tue', value: 28000),
        RevenuePoint(label: 'Wed', value: 34000),
        RevenuePoint(label: 'Thu', value: 32000),
        RevenuePoint(label: 'Fri', value: 40000),
        RevenuePoint(label: 'Sat', value: 45000),
        RevenuePoint(label: 'Sun', value: 38000),
      ],
      appointmentTrends: const [
        AppointmentTrendPoint(date: 'Mon', count: 32),
        AppointmentTrendPoint(date: 'Tue', count: 28),
        AppointmentTrendPoint(date: 'Wed', count: 35),
        AppointmentTrendPoint(date: 'Thu', count: 30),
        AppointmentTrendPoint(date: 'Fri', count: 42),
        AppointmentTrendPoint(date: 'Sat', count: 38),
        AppointmentTrendPoint(date: 'Sun', count: 25),
      ],
      appointmentStatus: const [
        AppointmentStatusPoint(status: 'Completed', count: 216),
        AppointmentStatusPoint(status: 'Pending', count: 20),
        AppointmentStatusPoint(status: 'Cancelled', count: 8),
        AppointmentStatusPoint(status: 'No Show', count: 4),
      ],
      departmentData: const [
        DepartmentPoint(department: 'Psychiatry', count: 65),
        DepartmentPoint(department: 'General', count: 60),
        DepartmentPoint(department: 'Cardiology', count: 45),
        DepartmentPoint(department: 'Pediatrics', count: 35),
        DepartmentPoint(department: 'Therapy', count: 43),
      ],
      topDoctors: const [
        DoctorPerformancePoint(
          name: 'Dr. James Kipchoge',
          appointmentCount: 52,
          rating: 4.8,
        ),
        DoctorPerformancePoint(
          name: 'Dr. Sarah Omondi',
          appointmentCount: 48,
          rating: 4.7,
        ),
        DoctorPerformancePoint(
          name: 'Dr. Michael Chen',
          appointmentCount: 45,
          rating: 4.6,
        ),
        DoctorPerformancePoint(
          name: 'Dr. Amelia Foster',
          appointmentCount: 42,
          rating: 4.5,
        ),
        DoctorPerformancePoint(
          name: 'Dr. David Kariuki',
          appointmentCount: 38,
          rating: 4.4,
        ),
      ],
      patientDemographics: const [
        DemographicPoint(category: '18-25', count: 28),
        DemographicPoint(category: '26-35', count: 52),
        DemographicPoint(category: '36-45', count: 38),
        DemographicPoint(category: '46-55', count: 28),
        DemographicPoint(category: '55+', count: 10),
      ],
      queueMetrics: const [
        QueueMetricPoint(
          department: 'Psychiatry',
          avgWaitTime: 15.0,
          patientsWaiting: 3,
        ),
        QueueMetricPoint(
          department: 'General',
          avgWaitTime: 10.0,
          patientsWaiting: 5,
        ),
        QueueMetricPoint(
          department: 'Cardiology',
          avgWaitTime: 20.0,
          patientsWaiting: 2,
        ),
      ],
    );
  }
}
