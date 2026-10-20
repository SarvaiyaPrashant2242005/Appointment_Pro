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

  void _log(String message) {
    debugPrint('[WebSocket] $message');
  }

  /// Connect to WebSocket server and optionally subscribe to a business
  void connect({String? businessId}) {
    if (_isDisposed) {
      _log('⚠️ Cannot connect, service is disposed.');
      return;
    }
    if (businessId != null && businessId.isNotEmpty) {
      _currentBusinessId = businessId;
    }

    _log('⚡ connect() requested | Status: ${_status.name.toUpperCase()} | Business: ${_currentBusinessId ?? "None"}');

    if (_status == WebSocketStatus.connected) {
      _log('🟢 Already CONNECTED. Ensuring business room is subscribed...');
      if (businessId != null && businessId.isNotEmpty) {
        joinBusiness(businessId);
      }
      return;
    }

    if (_status == WebSocketStatus.connecting) {
      _log('🟡 Already in CONNECTING state. Business room "$businessId" will be joined upon connection.');
      return;
    }

    _status = WebSocketStatus.connecting;
    _statusController.add(_status);
    _log('🟡 Status set to: CONNECTING');

    _doConnect();
  }

  Future<void> _doConnect() async {
    final rawWsUrl = ApiEndpoints.wsUrl;
    try {
      String wsUrl = rawWsUrl;
      // Append query parameter ?businessId=... for instant room assignment on handshake
      if (_currentBusinessId != null && _currentBusinessId!.isNotEmpty) {
        final uri = Uri.parse(wsUrl);
        final q = Map<String, String>.from(uri.queryParameters);
        q['businessId'] = _currentBusinessId!;
        wsUrl = uri.replace(queryParameters: q).toString();
      }

      _log('============================================================');
      _log('🔌 [SOCKET CONNECTING]');
      _log('   URL: $wsUrl');
      _log('   Business ID: ${_currentBusinessId ?? "None"}');
      _log('============================================================');

      // Resilient client with SSL tolerance for various mobile devices and proxies
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      client.connectionTimeout = const Duration(seconds: 10);

      final socket = await WebSocket.connect(
        wsUrl,
        customClient: client,
      ).timeout(
        const Duration(seconds: 12),
      );

      _socket = socket;
      _status = WebSocketStatus.connected;
      _statusController.add(_status);

      _log('============================================================');
      _log('🟢 [SOCKET CONNECTED SUCCESSFULLY]');
      _log('   Server: $wsUrl');
      _log('   ReadyState: ${socket.readyState} (OPEN)');
      _log('============================================================');

      // Send join_business message for backward compatibility and confirmation
      if (_currentBusinessId != null && _currentBusinessId!.isNotEmpty) {
        joinBusiness(_currentBusinessId!);
      }

      // Start ping heartbeat (20 seconds keepalive)
      _startPing();

      // Listen for incoming events from server
      socket.listen(
        (data) {
          try {
            final json = jsonDecode(data.toString()) as Map<String, dynamic>;
            final eventName = json['event'] ?? json['type'];

            if (eventName == 'pong') {
              _log('💓 Received heartbeat PONG from server (Connection healthy)');
              return;
            }

            if (eventName == 'connection:established') {
              _log('🤝 Handshake ACK: "${json['data']?['message'] ?? 'Connected to Live WebSocket'}"');
            } else if (eventName == 'business:joined') {
              _log('📡 Room subscription confirmed by server: businessId=${json['businessId']}');
            } else {
              _log('📩 [SOCKET EVENT] "$eventName" | Payload: $json');
            }

            _eventController.add(json);
          } catch (e) {
            _log('⚠️ JSON parse error on incoming event: $e | Raw: $data');
          }
        },
        onError: (error) {
          _log('============================================================');
          _log('🔴 [SOCKET ERROR]: $error');
          _log('============================================================');
          _handleDisconnect('Socket error: $error');
        },
        onDone: () {
          final code = socket.closeCode;
          final reason = socket.closeReason;
          _log('============================================================');
          _log('⚪ [SOCKET CLOSED BY SERVER]');
          _log('   Close Code: $code');
          _log('   Close Reason: ${reason ?? "None"}');
          _log('============================================================');
          _handleDisconnect('Closed by server (code: $code, reason: $reason)');
        },
        cancelOnError: true,
      );
    } catch (e, stack) {
      _log('============================================================');
      _log('🔴 [SOCKET CONNECTION FAILED]');
      _log('   URL: $rawWsUrl');
      _log('   Error: $e');
      _log('   Stack: $stack');
      _log('============================================================');
      _handleDisconnect('Connection attempt failed: $e');
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
        _log('📡 Sent "join_business" message for: $businessId');
      } catch (e) {
        _log('⚠️ Error sending join_business: $e');
      }
    } else {
      _log('⏳ joinBusiness($businessId) queued - will send once socket is CONNECTED (Current: ${_status.name.toUpperCase()})');
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_status == WebSocketStatus.connected && _socket != null) {
        try {
          _socket!.add(jsonEncode({'type': 'ping'}));
          _log('💓 Sent heartbeat PING to server');
        } catch (e) {
          _log('⚠️ Heartbeat PING failed: $e');
        }
      }
    });
  }

  void _handleDisconnect([String? reason]) {
    _pingTimer?.cancel();
    _socket = null;
    final previousStatus = _status;
    _status = WebSocketStatus.disconnected;
    _statusController.add(_status);

    _log('⚪ Status changed: ${previousStatus.name.toUpperCase()} -> DISCONNECTED${reason != null ? " ($reason)" : ""}');

    // Auto reconnect after 3 seconds
    if (!_isDisposed) {
      _reconnectTimer?.cancel();
      _log('🔄 Scheduling auto-reconnect in 3 seconds...');
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (!_isDisposed && _status == WebSocketStatus.disconnected) {
          _log('🔄 Executing auto-reconnect now...');
          connect(businessId: _currentBusinessId);
        }
      });
    }
  }

  /// Manually disconnect
  void disconnect() {
    _log('🛑 Manual disconnect() called');
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
    _log('🛑 dispose() called');
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

