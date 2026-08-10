import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';

/// State class representing the current Watchman's details.
class WatchmanState {
  final String watchName;
  final String watchId;
  final String buildId;
  final String buildName;
  final List wings;

  WatchmanState({
    required this.watchName,
    required this.watchId,
    required this.buildId,
    required this.buildName,
    required this.wings,
  });

  /// Creates a copy of the WatchmanState with the given fields replaced by new values.
  WatchmanState copyWith({
    String? watchName,
    String? watchId,
    String? buildId,
    String? buildName,
    List? wings,
  }) {
    return WatchmanState(
      watchName: watchName ?? this.watchName,
      watchId: watchId ?? this.watchId,
      buildId: buildId ?? this.buildId,
      buildName: buildName ?? this.buildName,
      wings: wings ?? this.wings,
    );
  }
}

/// StateNotifier that manages the WatchmanState.
class WatchmanNotifier extends StateNotifier<WatchmanState?> {
  WatchmanNotifier() : super(null);

  /// Updates the watchman state with the provided details.
  void setWatchmanData({
    required String watchName,
    required String watchId,
    required String buildId,
    required String buildName,
    required List wings,
  }) {
    logger.i(
        'setWatchmanData called with watchName: $watchName, watchId: $watchId, buildId: $buildId, buildName: $buildName');
    state = WatchmanState(
      watchName: watchName,
      watchId: watchId,
      buildId: buildId,
      buildName: buildName,
      wings: wings,
    );
    logger.i('setWatchmanData completed successfully');
  }
}

/// Provider to expose the WatchmanNotifier and its state to the UI.
final watchmanProvider =
    StateNotifierProvider<WatchmanNotifier, WatchmanState?>((ref) {
  return WatchmanNotifier();
});

/// StreamProvider that fetches real-time logs for the currently assigned building
/// based on the active WatchmanState. It automatically disposes when not in use.
final watchmanLogsProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  logger.d('watchmanLogsProvider stream initialized');
  final watchmanState = ref.watch(watchmanProvider);
  if (watchmanState == null || watchmanState.buildId.isEmpty) {
    return const Stream.empty();
  }

  DateTime now = Timestamp.now().toDate();
  DateTime previous = now.subtract(const Duration(days: 7));
  Timestamp prev = Timestamp.fromDate(previous);

  return FirebaseFirestore.instance
      .collection('buildings')
      .doc(watchmanState.buildId)
      .collection('logs')
      .orderBy('timestamp', descending: true)
      // For debugging purposes
      // .where('timestamp', isGreaterThan: prev)
      .snapshots();
});
