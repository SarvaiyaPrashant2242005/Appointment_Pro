import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';

/// Connection status of the Live WebSocket
enum WebSocketStatus {
  disconnected,
  connecting,
  connected;

  bool get isConnected => this == WebSocketStatus.connected;
  bool get isConnecting => this == WebSocketStatus.connecting;
}

/// Provider for the singleton WebSocketService
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// StreamProvider exposing live connection status changes
final webSocketStatusProvider = StreamProvider<WebSocketStatus>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  return wsService.statusStream;
});

/// Client service managing real-time WebSocket connection to AppointmentPro backend
class WebSocketService {
  WebSocket? _socket;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _currentBusinessId;
  bool _isDisposed = false;

  final _statusController = StreamController<WebSocketStatus>.broadcast();
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  WebSocketStatus _status = WebSocketStatus.disconnected;
  WebSocketStatus get status => _status;

  /// Connect to WebSocket server and optionally subscribe to a business
  void connect({String? businessId}) {
    if (_isDisposed) return;
    if (businessId != null && businessId.isNotEmpty) {
      _currentBusinessId = businessId;
    }

    if (_status == WebSocketStatus.connected ||
        _status == WebSocketStatus.connecting) {
      if (businessId != null && businessId.isNotEmpty) {
        joinBusiness(businessId);
      }
      return;
    }

    _status = WebSocketStatus.connecting;
    _statusController.add(_status);

    _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final wsUrl = ApiEndpoints.wsUrl;
      debugPrint('[WebSocket] 🔌 Connecting to $wsUrl ...');

      _socket = await WebSocket.connect(wsUrl).timeout(
        const Duration(seconds: 10),
      );

      _status = WebSocketStatus.connected;
      _statusController.add(_status);
      debugPrint('[WebSocket] ✅ Connected successfully to $wsUrl');

      // Subscribe to active business room if set
      if (_currentBusinessId != null && _currentBusinessId!.isNotEmpty) {
        joinBusiness(_currentBusinessId!);
      }

      // Start ping heartbeat
      _startPing();

      // Listen for incoming events from server
      _socket!.listen(
        (data) {
          try {
            final json = jsonDecode(data.toString()) as Map<String, dynamic>;
            _eventController.add(json);
          } catch (e) {
            debugPrint('[WebSocket] ⚠️ JSON parse error on incoming event: $e');
          }
        },
        onError: (error) {
          debugPrint('[WebSocket] ⚠️ Socket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('[WebSocket] ℹ️ Socket connection closed by remote.');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[WebSocket] ❌ Connection failed: $e');
      _handleDisconnect();
    }
  }

  /// Subscribe to a specific business's live booking event room
  void joinBusiness(String businessId) {
    _currentBusinessId = businessId;
    if (_status == WebSocketStatus.connected && _socket != null) {
      try {
        _socket!.add(
          jsonEncode({'type': 'join_business', 'businessId': businessId}),
        );
        debugPrint('[WebSocket] 📡 Joined business room: $businessId');
      } catch (e) {
        debugPrint('[WebSocket] ⚠️ Error sending join_business: $e');
      }
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_status == WebSocketStatus.connected && _socket != null) {
        try {
          _socket!.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      }
    });
  }

  void _handleDisconnect() {
    _pingTimer?.cancel();
    _socket = null;
    _status = WebSocketStatus.disconnected;
    _statusController.add(_status);

    // Auto reconnect after 4 seconds
    if (!_isDisposed) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 4), () {
        if (!_isDisposed && _status == WebSocketStatus.disconnected) {
          debugPrint('[WebSocket] 🔄 Attempting auto-reconnect...');
          connect(businessId: _currentBusinessId);
        }
      });
    }
  }

  /// Manually disconnect
  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
    _status = WebSocketStatus.disconnected;
    _statusController.add(_status);
  }

  /// Dispose all resources and streams
  void dispose() {
    _isDisposed = true;
    disconnect();
    _statusController.close();
    _eventController.close();
  }
}

/// Strongly typed representation of a WebSocket payload from AppointmentPro server
class WebSocketEvent {
  final String event;
  final String? businessId;
  final Map<String, dynamic> data;
  final DateTime? timestamp;

  const WebSocketEvent({
    required this.event,
    this.businessId,
    this.data = const {},
    this.timestamp,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final eventName = (json['event'] ?? json['type'] ?? '').toString();
    final bId = json['businessId']?.toString();
    final rawData = json['data'];
    final Map<String, dynamic> parsedData;
    if (rawData is Map<String, dynamic>) {
      parsedData = rawData;
    } else if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    } else {
      parsedData = {};
    }

    DateTime? ts;
    if (json['timestamp'] != null) {
      ts = DateTime.tryParse(json['timestamp'].toString());
    }

    return WebSocketEvent(
      event: eventName,
      businessId: bId,
      data: parsedData,
      timestamp: ts,
    );
  }

  Map<String, dynamic>? get bookingJson {
    final b = data['booking'];
    if (b is Map<String, dynamic>) return b;
    if (b is Map) return Map<String, dynamic>.from(b);
    return null;
  }
}

