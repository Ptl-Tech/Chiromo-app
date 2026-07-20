import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../../doctor/domain/entities/doctor_entity.dart';
import '../../data/datasources/appointment_remote_datasource.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:chiromo/features/doctor/presentation/providers/doctor_providers.dart';

final appointmentRemoteDataSourceProvider =
    Provider<AppointmentRemoteDataSource>((ref) {
      return AppointmentRemoteDataSource();
    });

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final dataSource = ref.watch(appointmentRemoteDataSourceProvider);
  return AppointmentRepositoryImpl(dataSource);
});

final patientAppointmentsProvider = FutureProvider<List<AppointmentEntity>>((
  ref,
) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return [];

  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getPatientAppointments(user.id);
});

final doctorAppointmentsProvider = FutureProvider<List<AppointmentEntity>>((
  ref,
) async {
  final DoctorEntity? doctorProfile = await ref.watch(
    currentDoctorProfileProvider.future,
  );
  if (doctorProfile == null) return [];

  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getDoctorAppointments(doctorProfile.id);
});

final doctorAppointmentsForDateProvider = FutureProvider.family<List<AppointmentEntity>, (String, DateTime)>((ref, args) async {
  final (doctorId, date) = args;
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getDoctorAppointmentsForDate(doctorId, date);
});
