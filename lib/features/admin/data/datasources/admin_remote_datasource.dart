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
    // Attempt to fetch from analytics_logs table and map real data.
    // If the table structure is missing, this will throw an error as expected for 'real data' wiring.
    final response = await _client.from('analytics_logs').select();

    // Process response into AnalyticsDataEntity
    // Assuming simple mapping for now since exact schema wasn't provided, but it enforces real DB usage.
    List<RevenuePoint> revenue = [];
    List<DepartmentPoint> department = [];
    for (var item in response) {
      if (item['type'] == 'revenue') {
        revenue.add(
          RevenuePoint(
            label: item['label'] ?? '',
            value: (item['value'] ?? 0).toDouble(),
          ),
        );
      } else if (item['type'] == 'department') {
        department.add(
          DepartmentPoint(
            department: item['label'] ?? '',
            count: item['value'] ?? 0,
          ),
        );
      }
    }
    return AnalyticsDataEntity(
      revenueData: revenue,
      departmentData: department,
    );
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
    return const AnalyticsDataEntity(
      revenueData: [
        RevenuePoint(label: 'Mon', value: 35000),
        RevenuePoint(label: 'Tue', value: 28000),
        RevenuePoint(label: 'Wed', value: 34000),
        RevenuePoint(label: 'Thu', value: 32000),
        RevenuePoint(label: 'Fri', value: 40000),
        RevenuePoint(label: 'Sat', value: 45000),
        RevenuePoint(label: 'Sun', value: 38000),
      ],
      departmentData: [
        DepartmentPoint(department: 'Psychiatry', count: 45),
        DepartmentPoint(department: 'Cardiology', count: 25),
        DepartmentPoint(department: 'Pediatrics', count: 20),
        DepartmentPoint(department: 'General', count: 38),
      ],
    );
  }
}
