import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/geo_coordinate.dart';
import '../../domain/models/tracking_snapshot.dart';
import '../../domain/models/tracking_status.dart';
import '../../domain/repositories/tracking_repository.dart';

class TrackingViewModel extends ChangeNotifier {
  TrackingViewModel({TrackingRepository? repository})
    : _repository = repository {
    _subscribe();
  }

  final TrackingRepository? _repository;
  StreamSubscription<TrackingSnapshot>? _subscription;
  TrackingViewState _state = const TrackingViewState();

  TrackingViewState get state => _state;

  bool get hasRepository => _repository != null;
  bool get isSubscribed => _subscription != null;

  void _subscribe() {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    _state = _state.copyWith(isLoading: true, isComplete: false);
    _subscription = repository.watchTracking().listen(
      _handleSnapshot,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  void _handleSnapshot(TrackingSnapshot snapshot) {
    _state = TrackingViewState(
      status: snapshot.status,
      riderLocation: snapshot.riderLocation,
      destination: snapshot.destination,
      remainingDistanceMeters: snapshot.remainingDistanceMeters,
      eta: snapshot.eta,
      updatedAt: snapshot.updatedAt,
      isLoading: false,
      isComplete: snapshot.status == TrackingStatus.delivered,
    );
    notifyListeners();
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _state = _state.copyWith(isLoading: false);
    notifyListeners();
  }

  void _handleDone() {
    _state = _state.copyWith(isLoading: false, isComplete: true);
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class TrackingViewState {
  const TrackingViewState({
    this.status = TrackingStatus.idle,
    this.riderLocation,
    this.destination,
    this.remainingDistanceMeters,
    this.eta,
    this.updatedAt,
    this.isLoading = true,
    this.isComplete = false,
  });

  final TrackingStatus status;
  final GeoCoordinate? riderLocation;
  final GeoCoordinate? destination;
  final double? remainingDistanceMeters;
  final Duration? eta;
  final DateTime? updatedAt;
  final bool isLoading;
  final bool isComplete;

  bool get hasLiveData => riderLocation != null && destination != null;

  TrackingViewState copyWith({
    TrackingStatus? status,
    GeoCoordinate? riderLocation,
    GeoCoordinate? destination,
    double? remainingDistanceMeters,
    Duration? eta,
    DateTime? updatedAt,
    bool? isLoading,
    bool? isComplete,
  }) {
    return TrackingViewState(
      status: status ?? this.status,
      riderLocation: riderLocation ?? this.riderLocation,
      destination: destination ?? this.destination,
      remainingDistanceMeters:
          remainingDistanceMeters ?? this.remainingDistanceMeters,
      eta: eta ?? this.eta,
      updatedAt: updatedAt ?? this.updatedAt,
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
