import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 单个端口的探测结果。
enum PortState { open, closed, timeout, error }

class PortResult {
  const PortResult({
    required this.port,
    required this.state,
    this.latencyMs = 0,
    this.message,
  });

  final int port;
  final PortState state;
  final int latencyMs;
  final String? message;

  String get stateLabel => switch (state) {
        PortState.open => '开放',
        PortState.closed => '关闭',
        PortState.timeout => '超时',
        PortState.error => '错误',
      };
}

/// 可替换的探测实现（测试注入假实现，不碰真实网络）。
abstract class PortProbe {
  Future<PortResult> probe(String host, int port, Duration timeout);
}

/// 生产实现：TCP connect 探测（dart:io，无第三方依赖）。
class TcpPortProbe implements PortProbe {
  const TcpPortProbe();

  @override
  Future<PortResult> probe(String host, int port, Duration timeout) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      sw.stop();
      socket.destroy();
      return PortResult(
          port: port,
          state: PortState.open,
          latencyMs: sw.elapsedMilliseconds);
    } on TimeoutException {
      return PortResult(port: port, state: PortState.timeout);
    } on SocketException catch (e) {
      sw.stop();
      final code = e.osError?.errorCode;
      final msg = e.message.toLowerCase();
      if (code == 10061 ||
          code == 111 ||
          msg.contains('refused') ||
          msg.contains('拒绝')) {
        return PortResult(
            port: port,
            state: PortState.closed,
            latencyMs: sw.elapsedMilliseconds);
      }
      if (code == 10060 || code == 110) {
        return PortResult(
            port: port,
            state: PortState.timeout,
            latencyMs: sw.elapsedMilliseconds);
      }
      return PortResult(
          port: port,
          state: PortState.error,
          latencyMs: sw.elapsedMilliseconds,
          message: e.message);
    } catch (e) {
      sw.stop();
      return PortResult(
          port: port,
          state: PortState.error,
          latencyMs: sw.elapsedMilliseconds,
          message: '$e');
    }
  }
}

/// 端口解析结果。
class PortParseResult {
  const PortParseResult(this.ports, this.errors);

  final List<int> ports;
  final List<String> errors;

  bool get ok => errors.isEmpty && ports.isNotEmpty;
}

class PortParser {
  static const int maxPorts = 1024;

  /// 支持 `80,443`、`8000-8010`、空格/换行/中文逗号分隔；去重并升序。
  static PortParseResult parse(String input) {
    final tokens = input
        .split(RegExp(r'[\s,;，、]+'))
        .where((t) => t.trim().isNotEmpty);
    final ports = <int>{};
    final errors = <String>[];
    final rangePattern = RegExp(r'^(\d{1,5})(?:\s*-\s*(\d{1,5}))?$');

    for (final raw in tokens) {
      final token = raw.trim();
      final m = rangePattern.firstMatch(token);
      if (m == null) {
        errors.add('无法识别：$token');
        continue;
      }
      final start = int.parse(m.group(1)!);
      final end = m.group(2) == null ? start : int.parse(m.group(2)!);
      if (start < 1 || start > 65535 || end < 1 || end > 65535) {
        errors.add('端口超出 1-65535：$token');
        continue;
      }
      if (end < start) {
        errors.add('范围顺序错误：$token');
        continue;
      }
      if (end - start + 1 > maxPorts ||
          ports.length + (end - start + 1) > maxPorts) {
        errors.add('端口数量超过上限 $maxPorts');
        continue;
      }
      for (var p = start; p <= end; p++) {
        ports.add(p);
      }
    }

    if (ports.isEmpty && errors.isEmpty) {
      errors.add('请输入端口，例如 80,443,8000-8010');
    }
    final sorted = ports.toList()..sort();
    return PortParseResult(sorted, errors);
  }

  /// 把用户输入归一化成主机名：支持 `http://host:port/path`、`host:port`、IP、域名。
  static String? normalizeHost(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    if (s.contains('://')) {
      final uri = Uri.tryParse(s);
      if (uri == null || uri.host.isEmpty) return null;
      return uri.host;
    }
    s = s.split('/').first;
    if (s.startsWith('[')) {
      final end = s.indexOf(']');
      return end > 1 ? s.substring(1, end) : null;
    }
    final first = s.indexOf(':');
    if (first > 0 && first == s.lastIndexOf(':')) {
      s = s.substring(0, first);
    }
    return s.isEmpty ? null : s;
  }
}

/// 常见端口 → 服务名（仅用于展示，不做识别）。
String serviceForPort(int port) => switch (port) {
      21 => 'FTP',
      22 => 'SSH',
      23 => 'Telnet',
      25 => 'SMTP',
      53 => 'DNS',
      80 => 'HTTP',
      110 => 'POP3',
      143 => 'IMAP',
      443 => 'HTTPS',
      445 => 'SMB',
      1433 => 'MSSQL',
      3306 => 'MySQL',
      3389 => 'RDP',
      5432 => 'PostgreSQL',
      6379 => 'Redis',
      8000 => 'HTTP-Alt',
      8080 => 'HTTP-Alt',
      8443 => 'HTTPS-Alt',
      27017 => 'MongoDB',
      _ => '',
    };

enum ScanStatus { idle, running, done, stopped }

/// 扫描状态：并发探测、进度、统计、可停止。
class PortScanController extends ChangeNotifier {
  PortScanController({PortProbe? probe})
      : _probe = probe ?? const TcpPortProbe();

  final PortProbe _probe;
  final List<PortResult> _results = <PortResult>[];
  ScanStatus _status = ScanStatus.idle;
  String _host = '';
  List<int> _ports = const <int>[];
  int _scanned = 0;
  int _timeoutMs = 800;
  int _concurrency = 24;
  bool _stopRequested = false;
  bool _disposed = false;

  ScanStatus get status => _status;
  bool get isRunning => _status == ScanStatus.running;
  bool get isStopping => isRunning && _stopRequested;
  String get host => _host;
  List<int> get ports => List<int>.unmodifiable(_ports);
  List<PortResult> get results => List<PortResult>.unmodifiable(_results);
  int get scanned => _scanned;
  int get total => _ports.length;
  int get timeoutMs => _timeoutMs;
  double get progress => _ports.isEmpty ? 0 : _scanned / _ports.length;
  int get openCount =>
      _results.where((r) => r.state == PortState.open).length;
  int get closedCount =>
      _results.where((r) => r.state == PortState.closed).length;
  int get problemCount => _results
      .where((r) =>
          r.state == PortState.timeout || r.state == PortState.error)
      .length;

  Future<void> scan({
    required String host,
    required List<int> ports,
    int timeoutMs = 800,
    int concurrency = 24,
  }) async {
    if (isRunning) return;
    _host = host;
    _ports = List<int>.from(ports)..sort();
    _timeoutMs = timeoutMs;
    _concurrency = concurrency.clamp(1, 64).toInt();
    _results.clear();
    _scanned = 0;
    _stopRequested = false;
    _status = ScanStatus.running;
    _notify();

    var next = 0;
    Future<void> worker() async {
      while (true) {
        if (_stopRequested) return;
        final i = next++;
        if (i >= _ports.length) return;
        final r = await _probe.probe(
            host, _ports[i], Duration(milliseconds: _timeoutMs));
        if (_disposed) return;
        _results.add(r);
        _scanned++;
        _notify();
      }
    }

    await Future.wait(
        List<Future<void>>.generate(_concurrency, (_) => worker()));
    if (_disposed) return;
    _status = _stopRequested ? ScanStatus.stopped : ScanStatus.done;
    _results.sort((a, b) => a.port.compareTo(b.port));
    _notify();
  }

  void stop() {
    if (isRunning && !_stopRequested) {
      _stopRequested = true;
      _notify();
    }
  }

  void clear() {
    if (isRunning) return;
    _results.clear();
    _scanned = 0;
    _status = ScanStatus.idle;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

