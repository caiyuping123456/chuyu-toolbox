import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 连接状态（UI 按 SPEC §7 的语义色展示）。
enum WsStatus { idle, connecting, connected, closed, error }

/// 日志方向。
enum WsDirection { sent, received, system }

class WsLogEntry {
  WsLogEntry({
    required this.direction,
    required this.text,
    DateTime? time,
    this.error = false,
  }) : time = time ?? DateTime.now();

  final WsDirection direction;
  final String text;
  final DateTime time;
  final bool error;

  String get timeLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}

/// 可替换的连接抽象（测试注入假实现，不碰真实网络）。
abstract class WsConnection {
  Stream<Object?> get stream;
  void send(String text);
  Future<void> close();
}

abstract class WsConnector {
  Future<WsConnection> connect(String url);
}

/// 生产实现：dart:io WebSocket（Windows 桌面直连，不引第三方包）。
class IoWsConnector implements WsConnector {
  const IoWsConnector();

  @override
  Future<WsConnection> connect(String url) async {
    final socket = await WebSocket.connect(url)
        .timeout(const Duration(seconds: 12));
    return _IoWsConnection(socket);
  }
}

class _IoWsConnection implements WsConnection {
  _IoWsConnection(this._socket);

  final WebSocket _socket;

  @override
  Stream<Object?> get stream => _socket;

  @override
  void send(String text) => _socket.add(text);

  @override
  Future<void> close() => _socket.close();
}

/// WebSocket 模块状态：连接 / 断开 / 收发 / 日志。UI 只读它并调用方法。
class WsController extends ChangeNotifier {
  WsController({WsConnector? connector})
      : _connector = connector ?? const IoWsConnector();

  final WsConnector _connector;
  final List<WsLogEntry> _log = <WsLogEntry>[];
  WsStatus _status = WsStatus.idle;
  WsConnection? _conn;
  StreamSubscription<Object?>? _sub;
  bool _disposed = false;

  WsStatus get status => _status;
  bool get isConnected => _status == WsStatus.connected;
  bool get isBusy => _status == WsStatus.connecting;
  List<WsLogEntry> get log => List<WsLogEntry>.unmodifiable(_log);

  String get statusLabel => switch (_status) {
        WsStatus.idle => '未连接',
        WsStatus.connecting => '连接中…',
        WsStatus.connected => '已连接',
        WsStatus.closed => '已断开',
        WsStatus.error => '连接失败',
      };

  Future<void> connect(String url) async {
    if (isBusy) return;
    final target = url.trim();
    if (!target.startsWith('ws://') && !target.startsWith('wss://')) {
      _status = WsStatus.error;
      _addSystem('URL 需以 ws:// 或 wss:// 开头', error: true);
      _notify();
      return;
    }
    if (_conn != null) await disconnect();
    _status = WsStatus.connecting;
    _notify();
    try {
      final conn = await _connector.connect(target);
      if (_disposed) {
        await conn.close();
        return;
      }
      _conn = conn;
      _sub = conn.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _status = WsStatus.connected;
      _addSystem('已连接到 $target');
    } catch (e) {
      if (_disposed) return;
      _conn = null;
      _status = WsStatus.error;
      _addSystem('连接失败：${_friendly(e)}', error: true);
    }
    _notify();
  }

  void send(String text) {
    final msg = text.trim();
    if (msg.isEmpty) return;
    if (_conn == null || !isConnected) {
      _addSystem('未连接，无法发送', error: true);
      _notify();
      return;
    }
    try {
      _conn!.send(msg);
      _log.add(WsLogEntry(direction: WsDirection.sent, text: msg));
    } catch (e) {
      _addSystem('发送失败：${_friendly(e)}', error: true);
    }
    _notify();
  }

  Future<void> disconnect() async {
    final conn = _conn;
    final sub = _sub;
    _conn = null;
    _sub = null;
    _status = WsStatus.closed;
    _addSystem('已断开连接');
    _notify();
    sub?.cancel();
    try {
      await conn?.close();
    } catch (_) {
      // 关闭失败不影响 UI 状态
    }
  }

  void clear() {
    _log.clear();
    _notify();
  }

  void _onData(Object? data) {
    final text = data is List<int>
        ? utf8.decode(data, allowMalformed: true)
        : '$data';
    _log.add(WsLogEntry(direction: WsDirection.received, text: text));
    _notify();
  }

  void _onError(Object error) {
    _status = WsStatus.error;
    _addSystem('连接错误：${_friendly(error)}', error: true);
    _notify();
  }

  void _onDone() {
    if (_status == WsStatus.connected) {
      _status = WsStatus.closed;
      _addSystem('服务端已关闭连接');
      _notify();
    }
  }

  void _addSystem(String text, {bool error = false}) {
    _log.add(
        WsLogEntry(direction: WsDirection.system, text: text, error: error));
  }

  String _friendly(Object e) {
    if (e is TimeoutException) return '连接超时';
    final s = e.toString();
    if (s.contains('Connection refused')) return '连接被拒绝（目标未启动？）';
    if (s.contains('HandshakeException')) return '握手失败（证书或协议不匹配）';
    return s.replaceFirst('Exception: ', '');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _conn?.close();
    super.dispose();
  }
}


