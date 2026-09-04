import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/thought_remote_datasource.dart';
import '../../data/models/thought_record_model.dart';

/// Providers for the Business-Central-backed thought record feature.

final thoughtDataSourceProvider = Provider<ThoughtRemoteDataSource>((ref) {
  return ThoughtRemoteDataSource();
});

/// The patient's worked-through thoughts, newest first.
final thoughtRecordsProvider = FutureProvider<List<ThoughtRecord>>((ref) {
  return ref.watch(thoughtDataSourceProvider).getThoughtRecords();
});

/// Imperative thought record actions. Errors are rethrown so the calling
/// screen can show them inline rather than having them swallowed.
final thoughtNotifierProvider =
    StateNotifierProvider<ThoughtNotifier, AsyncValue<void>>((ref) {
      return ThoughtNotifier(ref);
    });

class ThoughtNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ThoughtNotifier(this._ref) : super(const AsyncValue.data(null));

  ThoughtRemoteDataSource get _source => _ref.read(thoughtDataSourceProvider);

  Future<int> save({
    int? entryNo,
    required DateTime recordedAt,
    required String situation,
    required String automaticThought,
    required String emotion,
    required int emotionBefore,
    required int emotionAfter,
    required String balancedThought,
    String notes = '',
    bool shareWithDoctor = false,
    List<Evidence> evidence = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final saved = await _source.saveThoughtRecord(
        entryNo: entryNo,
        recordedAt: recordedAt,
        situation: situation,
        automaticThought: automaticThought,
        emotion: emotion,
        emotionBefore: emotionBefore,
        emotionAfter: emotionAfter,
        balancedThought: balancedThought,
        notes: notes,
        shareWithDoctor: shareWithDoctor,
        evidence: evidence,
      );
      _ref.invalidate(thoughtRecordsProvider);
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
      await _source.deleteThoughtRecord(entryNo);
      _ref.invalidate(thoughtRecordsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
