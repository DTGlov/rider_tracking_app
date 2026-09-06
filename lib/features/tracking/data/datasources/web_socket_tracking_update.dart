import 'dart:convert';

import '../../domain/models/geo_coordinate.dart';
import '../../domain/models/tracking_status.dart';

class WebSocketTrackingUpdate {
  const WebSocketTrackingUpdate({
    required this.tripId,
    required this.sequence,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.remainingDistanceMeters,
    required this.etaSeconds,
    required this.status,
  });

  factory WebSocketTrackingUpdate.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Tracking message must be a JSON object');
    }
    return WebSocketTrackingUpdate.fromJsonMap(decoded);
  }

  factory WebSocketTrackingUpdate.fromJsonMap(Map<String, dynamic> json) {
    return WebSocketTrackingUpdate(
      tripId: _requiredString(json, 'tripId'),
      sequence: _requiredPositiveInt(json, 'sequence'),
      timestamp: _parseTimestamp(json),
      latitude: _requiredDouble(json, 'latitude'),
      longitude: _requiredDouble(json, 'longitude'),
      remainingDistanceMeters: _requiredNonNegativeDouble(
        json,
        'remainingDistanceMeters',
      ),
      etaSeconds: _requiredNonNegativeInt(json, 'etaSeconds'),
      status: _parseStatus(json),
    );
  }

  final String tripId;
  final int sequence;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double remainingDistanceMeters;
  final int etaSeconds;
  final TrackingStatus status;

  GeoCoordinate get riderLocation =>
      GeoCoordinate(latitude: latitude, longitude: longitude);

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw FormatException('Tracking field "$key" must be a non-empty string');
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    throw FormatException('Tracking field "$key" must be an integer');
  }

  static int _requiredPositiveInt(Map<String, dynamic> json, String key) {
    final value = _requiredInt(json, key);
    if (value > 0) {
      return value;
    }
    throw FormatException('Tracking field "$key" must be positive');
  }

  static int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
    final value = _requiredInt(json, key);
    if (value >= 0) {
      return value;
    }
    throw FormatException('Tracking field "$key" must not be negative');
  }

  static double _requiredDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    throw FormatException('Tracking field "$key" must be a number');
  }

  static double _requiredNonNegativeDouble(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = _requiredDouble(json, key);
    if (value >= 0) {
      return value;
    }
    throw FormatException('Tracking field "$key" must not be negative');
  }

  static DateTime _parseTimestamp(Map<String, dynamic> json) {
    final value = _requiredString(json, 'timestamp');
    final hasRfc3339Shape = RegExp(
      r'^\d{4}-\d{2}-\d{2}T.+(?:Z|[+-]\d{2}:\d{2})$',
    ).hasMatch(value);
    if (!hasRfc3339Shape) {
      throw const FormatException('Tracking field "timestamp" must be RFC3339');
    }
    try {
      return DateTime.parse(value).toUtc();
    } on FormatException {
      throw FormatException('Tracking field "timestamp" must be RFC3339');
    }
  }

  static TrackingStatus _parseStatus(Map<String, dynamic> json) {
    final value = _requiredString(json, 'status');
    return switch (value) {
      'riderAssigned' => TrackingStatus.riderAssigned,
      'enRoute' => TrackingStatus.enRoute,
      'arriving' => TrackingStatus.arriving,
      'delivered' => TrackingStatus.delivered,
      _ => throw FormatException('Unsupported tracking status "$value"'),
    };
  }
}
