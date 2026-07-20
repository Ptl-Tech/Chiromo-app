import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/analytics_data_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _dataSource;

  AdminRepositoryImpl(this._dataSource);

  @override
  Future<List<BranchEntity>> getBranches() => _dataSource.getBranches();

  @override
  Future<AnalyticsDataEntity> getAnalyticsData() =>
      _dataSource.getAnalyticsData();
}
