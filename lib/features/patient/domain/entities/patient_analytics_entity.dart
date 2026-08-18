class PatientAnalyticsEntity {
  final PatientHealthStats healthStats;
  final List<MoodEntry> moodHistory;
  final List<AppointmentStats> appointmentStats;
  final List<MedicationAdherence> medications;
  final List<ExerciseRecord> exercises;
  final List<SleepRecord> sleepRecords;

  const PatientAnalyticsEntity({
    required this.healthStats,
    required this.moodHistory,
    required this.appointmentStats,
    required this.medications,
    required this.exercises,
    required this.sleepRecords,
  });
}

class PatientHealthStats {
  final int totalAppointments;
  final int completedAppointments;
  final double appointmentCompletionRate;
  final int activePrescriptions;
  final double averageMood; // 1-10 scale
  final int streak; // Days of consistent check-ins

  const PatientHealthStats({
    required this.totalAppointments,
    required this.completedAppointments,
    required this.appointmentCompletionRate,
    required this.activePrescriptions,
    required this.averageMood,
    required this.streak,
  });
}

class MoodEntry {
  final String date;
  final int moodScore; // 1-10
  final String? note;

  const MoodEntry({required this.date, required this.moodScore, this.note});
}

class AppointmentStats {
  final String month;
  final int count;

  const AppointmentStats({required this.month, required this.count});
}

class MedicationAdherence {
  final String medicationName;
  final int adherencePercentage;
  final String frequency;

  const MedicationAdherence({
    required this.medicationName,
    required this.adherencePercentage,
    required this.frequency,
  });
}

class ExerciseRecord {
  final String date;
  final int minutesDone;
  final String type;

  const ExerciseRecord({
    required this.date,
    required this.minutesDone,
    required this.type,
  });
}

class SleepRecord {
  final String date;
  final double hoursSlept;
  final String quality; // Good, Fair, Poor

  const SleepRecord({
    required this.date,
    required this.hoursSlept,
    required this.quality,
  });
}
