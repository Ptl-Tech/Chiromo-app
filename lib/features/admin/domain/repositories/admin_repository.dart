import '../entities/branch_entity.dart';
import '../entities/analytics_data_entity.dart';

abstract class AdminRepository {
  Future<List<BranchEntity>> getBranches();
  Future<AnalyticsDataEntity> getAnalyticsData();
}
