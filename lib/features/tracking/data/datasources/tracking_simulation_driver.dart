import 'dart:async';

abstract class TrackingSimulationDriver {
  Stream<void> get ticks;

  Future<void> dispose();
}

class PeriodicTrackingSimulationDriver implements TrackingSimulationDriver {
  PeriodicTrackingSimulationDriver({required Duration interval})
    : _interval = interval;

  final Duration _interval;
  late final StreamController<void> _controller =
      StreamController<void>.broadcast(onListen: _start, onCancel: _stop);
  Timer? _timer;
  bool _disposed = false;

  @override
  Stream<void> get ticks => _controller.stream;

  void _start() {
    if (_disposed || _timer != null) {
      return;
    }

    _timer = Timer.periodic(_interval, (_) {
      if (!_controller.isClosed) {
        _controller.add(null);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _stop();
    await _controller.close();
  }
}

class ManualTrackingSimulationDriver implements TrackingSimulationDriver {
  ManualTrackingSimulationDriver();

  late final StreamController<void> _controller =
      StreamController<void>.broadcast(
        onListen: () {
          _listenerCount++;
        },
        onCancel: () {
          if (_listenerCount > 0) {
            _listenerCount--;
          }
        },
      );
  int _listenerCount = 0;
  bool _disposed = false;

  @override
  Stream<void> get ticks => _controller.stream;

  int get activeListenerCount => _listenerCount;

  void advance([int count = 1]) {
    for (var index = 0; index < count; index++) {
      if (_disposed || _controller.isClosed) {
        return;
      }
      _controller.add(null);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    await _controller.close();
  }
}
