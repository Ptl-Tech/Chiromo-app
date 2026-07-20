import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch_model.dart';
import '../../domain/entities/analytics_data_entity.dart';

class AdminRemoteDataSource {
  final SupabaseClient _client;

  AdminRemoteDataSource(this._client);

  Future<List<BranchModel>> getBranches() async {
    try {
      final data = await _client.from('branches').select().order('name');
      return data.map((json) => BranchModel.fromJson(json)).toList();
    } catch (e) {
      // If table doesn't exist yet, return dummy data to avoid breaking the UI during dev
      if (e.toString().contains('relation "public.branches" does not exist')) {
        return _getDummyBranches();
      }
      rethrow;
    }
  }

  Future<AnalyticsDataEntity> getAnalyticsData() async {
    try {
      // Attempt to fetch from analytics_logs table.
      // When the table schema is defined, parse real data here.
      await _client.from('analytics_logs').select().limit(10);
      return _getDummyAnalytics();
    } catch (e) {
      return _getDummyAnalytics();
    }
  }

  List<BranchModel> _getDummyBranches() {
    return [
      BranchModel(id: '1', name: 'Chiromo Lane', type: 'Headquarters', location: 'Muthithi Road, Westlands', isActive: true, createdAt: DateTime.now()),
      BranchModel(id: '2', name: 'Bustani', type: 'Rehabilitation Center', location: 'Lavington, Nairobi', isActive: true, createdAt: DateTime.now()),
      BranchModel(id: '3', name: 'Mombasa Branch', type: 'Outpatient Clinic', location: 'Nyali, Mombasa', isActive: false, createdAt: DateTime.now()),
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
