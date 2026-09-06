enum TrackingSourceMode { local, webSocket }

class TrackingAppConfig {
  const TrackingAppConfig._({required this.sourceMode, this.webSocketUrl});

  factory TrackingAppConfig.fromEnvironment() {
    return TrackingAppConfig.fromValues(
      source: const String.fromEnvironment(
        'TRACKING_SOURCE',
        defaultValue: 'local',
      ),
      webSocketUrl: const String.fromEnvironment('TRACKING_WS_URL'),
    );
  }

  factory TrackingAppConfig.fromValues({
    String source = 'local',
    String webSocketUrl = '',
  }) {
    final sourceMode = switch (source) {
      'local' => TrackingSourceMode.local,
      'websocket' => TrackingSourceMode.webSocket,
      _ => throw FormatException(
        'Unsupported TRACKING_SOURCE "$source". Use "local" or "websocket".',
      ),
    };

    if (sourceMode == TrackingSourceMode.local) {
      return const TrackingAppConfig._(sourceMode: TrackingSourceMode.local);
    }

    final parsedUrl = Uri.tryParse(webSocketUrl);
    if (parsedUrl == null ||
        (parsedUrl.scheme != 'ws' && parsedUrl.scheme != 'wss') ||
        parsedUrl.host.isEmpty) {
      throw const FormatException(
        'TRACKING_WS_URL must be a valid ws:// or wss:// URL when '
        'TRACKING_SOURCE is "websocket".',
      );
    }

    return TrackingAppConfig._(sourceMode: sourceMode, webSocketUrl: parsedUrl);
  }

  final TrackingSourceMode sourceMode;
  final Uri? webSocketUrl;
}
