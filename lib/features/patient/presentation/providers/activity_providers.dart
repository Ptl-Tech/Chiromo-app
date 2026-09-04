import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/activity_remote_datasource.dart';
import '../../data/models/activity_plan_model.dart';

/// Providers for the Business-Central-backed behavioural activation feature.

final activityDataSourceProvider = Provider<ActivityRemoteDataSource>((ref) {
  return ActivityRemoteDataSource();
});

final activityPlansProvider = FutureProvider<List<ActivityPlan>>((ref) {
  return ref.watch(activityDataSourceProvider).getActivityPlans();
});

/// Activities still ahead, soonest first — what the patient is working towards.
final upcomingActivitiesProvider = FutureProvider<List<ActivityPlan>>((
  ref,
) async {
  final all = await ref.watch(activityPlansProvider.future);
  final upcoming = all.where((a) => a.isUpcoming).toList()..sort(_byPlannedAt);
  return upcoming;
});

/// Planned activities whose day has passed with nothing recorded.
///
/// Listed first rather than buried. The prompt to say what happened —
/// including that it did not — is the part of the exercise that produces the
/// evidence, and an activity that quietly ages out produces none.
final awaitingActivitiesProvider = FutureProvider<List<ActivityPlan>>((
  ref,
) async {
  final all = await ref.watch(activityPlansProvider.future);
  final overdue = all.where((a) => a.isOverdue).toList()
    ..sort((a, b) => _byPlannedAt(b, a));
  return overdue;
});

/// Everything already recorded, most recent first.
final finishedActivitiesProvider = FutureProvider<List<ActivityPlan>>((
  ref,
) async {
  final all = await ref.watch(activityPlansProvider.future);
  final done = all.where((a) => !a.isPlanned).toList()
    ..sort((a, b) => _byPlannedAt(b, a));
  return done;
});

/// Imperative activity actions. Errors are rethrown so the calling screen can
/// show them inline.
final activityNotifierProvider =
    StateNotifierProvider<ActivityNotifier, AsyncValue<void>>((ref) {
      return ActivityNotifier(ref);
    });

class ActivityNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ActivityNotifier(this._ref) : super(const AsyncValue.data(null));

  ActivityRemoteDataSource get _source => _ref.read(activityDataSourceProvider);

  Future<int> save({
    int? entryNo,
    required String activity,
    required DateTime plannedAt,
    bool includeTime = false,
    int anticipatedPleasure = 0,
    int anticipatedAchievement = 0,
    ActivityStatus status = ActivityStatus.planned,
    int actualPleasure = 0,
    int actualAchievement = 0,
    int moodBefore = 0,
    int moodAfter = 0,
    String skipReason = '',
    String notes = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final saved = await _source.saveActivityPlan(
        entryNo: entryNo,
        activity: activity,
        plannedAt: plannedAt,
        includeTime: includeTime,
        anticipatedPleasure: anticipatedPleasure,
        anticipatedAchievement: anticipatedAchievement,
        status: status,
        actualPleasure: actualPleasure,
        actualAchievement: actualAchievement,
        moodBefore: moodBefore,
        moodAfter: moodAfter,
        skipReason: skipReason,
        notes: notes,
      );
      _ref.invalidate(activityPlansProvider);
      state = const AsyncValue.data(null);
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> delete(int entryNo) async {
    state = const AsyncValue.loading();
    try {
      await _source.deleteActivityPlan(entryNo);
      _ref.invalidate(activityPlansProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

int _byPlannedAt(ActivityPlan a, ActivityPlan b) {
  final left = a.plannedAt;
  final right = b.plannedAt;
  if (left == null && right == null) return a.entryNo.compareTo(b.entryNo);
  if (left == null) return 1;
  if (right == null) return -1;
  return left.compareTo(right);
}
