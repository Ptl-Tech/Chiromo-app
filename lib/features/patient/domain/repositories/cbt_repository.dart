import '../entities/cbt_exercise_entity.dart';

/// Abstract repository for CBT exercise operations.
abstract class CbtRepository {
  Future<List<CbtExerciseEntity>> getExercises(String patientId);
  Future<CbtExerciseEntity> createExercise(CbtExerciseEntity exercise);
  Future<CbtExerciseEntity> updateExercise(CbtExerciseEntity exercise);
  Future<void> deleteExercise(String exerciseId);
}
