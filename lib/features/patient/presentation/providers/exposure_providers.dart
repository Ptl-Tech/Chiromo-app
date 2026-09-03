import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/exposure_remote_datasource.dart';
import '../../data/models/exposure_ladder_model.dart';

/// Providers for the Business-Central-backed exposure ladder feature.

final exposureDataSourceProvider = Provider<ExposureRemoteDataSource>((ref) {
  return ExposureRemoteDataSource();
});

/// The clinic's template library, as configured in BC. Cached for the session:
/// the library changes rarely, and re-fetching it every time someone opens the
/// create screen would put a round trip in front of the form for no benefit.
final exposureTemplatesProvider = FutureProvider<List<ExposureTemplate>>((ref) {
  return ref.watch(exposureDataSourceProvider).getTemplates();
});

/// The signed-in patient's ladders, newest first.
final exposureLaddersProvider = FutureProvider<List<ExposureLadder>>((ref) {
  return ref.watch(exposureDataSourceProvider).getLadders();
});

/// One ladder by entry number, read out of the list rather than fetched on its
/// own — the list is already loaded by the time anyone opens a ladder, and a
/// second endpoint for a single ladder would only add a round trip.
final exposureLadderProvider = FutureProvider.family<ExposureLadder?, int>((
  ref,
  entryNo,
) async {
  final ladders = await ref.watch(exposureLaddersProvider.future);
  for (final ladder in ladders) {
    if (ladder.entryNo == entryNo) return ladder;
  }
  return null;
});

/// Attempts logged against one ladder, newest first.
final exposureTrialsProvider = FutureProvider.family<List<ExposureTrial>, int>((
  ref,
  ladderEntryNo,
) {
  return ref
      .watch(exposureDataSourceProvider)
      .getTrials(ladderEntryNo: ladderEntryNo);
});

/// The attempts logged against one particular rung, oldest first.
///
/// This is the evidence a patient needs and cannot get from any single
/// session: within one attempt the anxiety simply feels bad, and the fall that
/// shows the work is doing something is only visible across repeats. Read
/// oldest-first because that is the direction the trend reads in.
final stepTrialsProvider =
    FutureProvider.family<List<ExposureTrial>, ({int ladderEntryNo, int rank})>(
      (ref, key) async {
        final trials = await ref.watch(
          exposureTrialsProvider(key.ladderEntryNo).future,
        );

        final forStep = trials.where((t) => t.stepRank == key.rank).toList()
          ..sort((a, b) {
            final left = a.recordedAt;
            final right = b.recordedAt;
            if (left == null || right == null) {
              return a.entryNo.compareTo(b.entryNo);
            }
            return left.compareTo(right);
          });

        return forStep;
      },
    );

/// Imperative exposure ladder actions. Errors are rethrown so the calling
/// screen can show them inline rather than having them swallowed into global
/// state.
final exposureNotifierProvider =
    StateNotifierProvider<ExposureNotifier, AsyncValue<void>>((ref) {
      return ExposureNotifier(ref);
    });

class ExposureNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ExposureNotifier(this._ref) : super(const AsyncValue.data(null));

  ExposureRemoteDataSource get _source => _ref.read(exposureDataSourceProvider);

  Future<int> createLadder({
    String? templateCode,
    required String fear,
    List<ExposureStep> steps = const [],
    bool shareWithDoctor = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final entryNo = await _source.createLadder(
        templateCode: templateCode,
        fear: fear,
        steps: steps,
        shareWithDoctor: shareWithDoctor,
      );
      _ref.invalidate(exposureLaddersProvider);
      state = const AsyncValue.data(null);
      return entryNo;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Moves a ladder to a different rung. The patient decides when — nothing
  /// here advances a ladder on their behalf.
  Future<void> setCurrentStep({
    required int ladderEntryNo,
    required int stepRank,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _source.setCurrentStep(
        ladderEntryNo: ladderEntryNo,
        stepRank: stepRank,
      );
      _ref.invalidate(exposureLaddersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logTrial({
    required int ladderEntryNo,
    required int stepRank,
    required DateTime recordedAt,
    required int sudsBefore,
    required int sudsAfter,
    String notes = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _source.logTrial(
        ladderEntryNo: ladderEntryNo,
        stepRank: stepRank,
        recordedAt: recordedAt,
        sudsBefore: sudsBefore,
        sudsAfter: sudsAfter,
        notes: notes,
      );
      _ref.invalidate(exposureTrialsProvider(ladderEntryNo));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteLadder(int ladderEntryNo) async {
    state = const AsyncValue.loading();
    try {
      await _source.deleteLadder(ladderEntryNo);
      _ref.invalidate(exposureLaddersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
