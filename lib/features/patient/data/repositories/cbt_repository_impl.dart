import '../../domain/entities/cbt_exercise_entity.dart';
import '../../domain/repositories/cbt_repository.dart';
import '../datasources/cbt_remote_datasource.dart';
import '../models/cbt_exercise_model.dart';

/// Concrete implementation of [CbtRepository].
class CbtRepositoryImpl implements CbtRepository {
  final CbtRemoteDataSource _dataSource;

  CbtRepositoryImpl(this._dataSource);

  @override
  Future<List<CbtExerciseEntity>> getExercises(String patientId) {
    return _dataSource.getExercises(patientId);
  }

  @override
  Future<CbtExerciseEntity> createExercise(CbtExerciseEntity exercise) {
    return _dataSource.createExercise(CbtExerciseModel.fromEntity(exercise));
  }

  @override
  Future<CbtExerciseEntity> updateExercise(CbtExerciseEntity exercise) {
    return _dataSource.updateExercise(CbtExerciseModel.fromEntity(exercise));
  }

  @override
  Future<void> deleteExercise(String exerciseId) {
    return _dataSource.deleteExercise(exerciseId);
  }
}
