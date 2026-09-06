import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'web_socket_tracking_update.dart';

typedef WebSocketConnectionFactory = WebSocketTrackingConnection Function(
  Uri url,
);

abstract interface class WebSocketTrackingConnection {
  Stream<Object?> get messages;

  Future<void> close();
}

class WebSocketTrackingDataSource {
  WebSocketTrackingDataSource({
    required this.url,
    WebSocketConnectionFactory? connectionFactory,
  }) : _connectionFactory = connectionFactory ?? _connect;

  final Uri url;
  final WebSocketConnectionFactory _connectionFactory;

  Stream<WebSocketTrackingUpdate> watchUpdates() {
    late final StreamController<WebSocketTrackingUpdate> controller;
    WebSocketTrackingConnection? connection;
    StreamSubscription<Object?>? subscription;
    var isCleaningUp = false;

    Future<void> cleanup() async {
      if (isCleaningUp) {
        return;
      }
      isCleaningUp = true;
      await subscription?.cancel();
      await connection?.close();
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller = StreamController<WebSocketTrackingUpdate>(
      onListen: () {
        try {
          connection = _connectionFactory(url);
          subscription = connection!.messages.listen(
            (message) {
              try {
                controller.add(
                  WebSocketTrackingUpdate.fromJson(_messageText(message)),
                );
              } on Object catch (error, stackTrace) {
                controller.addError(error, stackTrace);
              }
            },
            onError: controller.addError,
            onDone: () => unawaited(cleanup()),
            cancelOnError: false,
          );
        } on Object catch (error, stackTrace) {
          controller.addError(error, stackTrace);
          unawaited(cleanup());
        }
      },
      onCancel: cleanup,
    );

    return controller.stream;
  }

  static WebSocketTrackingConnection _connect(Uri url) {
    return _ChannelTrackingConnection(WebSocketChannel.connect(url));
  }
}

String _messageText(Object? message) {
  if (message is String) {
    return message;
  }
  if (message is List<int>) {
    return utf8.decode(message);
  }
  throw FormatException(
    'Tracking WebSocket message must be text, got ${message.runtimeType}',
  );
}

class _ChannelTrackingConnection implements WebSocketTrackingConnection {
  _ChannelTrackingConnection(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<Object?> get messages => _channel.stream;

  @override
  Future<void> close() => _channel.sink.close();
}
