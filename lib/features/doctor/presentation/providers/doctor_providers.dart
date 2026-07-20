import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../../data/datasources/doctor_remote_datasource.dart';
import '../../data/repositories/doctor_repository_impl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final doctorRemoteDataSourceProvider = Provider<DoctorRemoteDataSource>((ref) {
  return DoctorRemoteDataSource();
});

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  final dataSource = ref.watch(doctorRemoteDataSourceProvider);
  return DoctorRepositoryImpl(dataSource);
});

final allDoctorsProvider = FutureProvider<List<DoctorEntity>>((ref) async {
  final repository = ref.watch(doctorRepositoryProvider);
  return repository.getAllDoctors();
});

final currentDoctorProfileProvider = FutureProvider<DoctorEntity?>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null || !user.role.isDoctor) return null;

  final repository = ref.watch(doctorRepositoryProvider);
  return repository.getDoctorByUserId(user.id);
});
