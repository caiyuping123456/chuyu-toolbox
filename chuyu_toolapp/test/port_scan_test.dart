import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/modules/port_scan/port_scanner.dart';

class FakeProbe implements PortProbe {
  FakeProbe(this.states, {this.delay = Duration.zero});

  final Map<int, PortState> states;
  final Duration delay;
  final List<int> probed = <int>[];

  @override
  Future<PortResult> probe(String host, int port, Duration timeout) async {
    probed.add(port);
    if (delay.inMilliseconds > 0) {
      await Future<void>.delayed(delay);
    }
    final state = states[port] ?? PortState.closed;
    return PortResult(
      port: port,
      state: state,
      latencyMs: state == PortState.open ? 3 : 0,
    );
  }
}

void main() {
  test('解析：列表 / 范围 / 去重 / 排序', () {
    final r = PortParser.parse('443, 80 80\n8000-8002，22');
    expect(r.errors, isEmpty);
    expect(r.ports, <int>[22, 80, 443, 8000, 8001, 8002]);
  });

  test('解析：非法输入', () {
    final r = PortParser.parse('abc, 70000, 9000-8000');
    expect(r.ports, isEmpty);
    expect(r.errors, hasLength(3));
  });

  test('解析：数量上限', () {
    final r = PortParser.parse('1-2000');
    expect(r.ports, isEmpty);
    expect(r.errors.single, contains('1024'));
  });

  test('主机归一化', () {
    expect(PortParser.normalizeHost('http://localhost:8080/path'), 'localhost');
    expect(PortParser.normalizeHost('127.0.0.1:22'), '127.0.0.1');
    expect(PortParser.normalizeHost('  '), isNull);
  });

  test('TcpPortProbe：本地回环开放 / 关闭', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close());

    final open = await const TcpPortProbe()
        .probe('127.0.0.1', server.port, const Duration(milliseconds: 500));
    expect(open.state, PortState.open);
    expect(open.latencyMs, greaterThanOrEqualTo(0));

    final closedServer = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final closedPort = closedServer.port;
    await closedServer.close();
    final closed = await const TcpPortProbe()
        .probe('127.0.0.1', closedPort, const Duration(milliseconds: 500));
    expect(closed.state, isNot(PortState.open));
  });

  test('控制器：并发扫描 / 统计 / 排序 / 清空', () async {
    final probe = FakeProbe({
      80: PortState.open,
      443: PortState.closed,
      8080: PortState.timeout,
    }, delay: const Duration(milliseconds: 5));
    final c = PortScanController(probe: probe);
    addTearDown(c.dispose);

    await c.scan(
        host: '127.0.0.1',
        ports: <int>[8080, 80, 443],
        timeoutMs: 200,
        concurrency: 2);

    expect(c.status, ScanStatus.done);
    expect(c.results.map((r) => r.port).toList(), <int>[80, 443, 8080]);
    expect(c.openCount, 1);
    expect(c.closedCount, 1);
    expect(c.problemCount, 1);
    expect(c.scanned, 3);
    expect(c.progress, 1.0);

    c.clear();
    expect(c.results, isEmpty);
    expect(c.status, ScanStatus.idle);
  });

  test('控制器：可停止', () async {
    final c = PortScanController(
        probe: FakeProbe(const <int, PortState>{},
            delay: const Duration(milliseconds: 30)));
    addTearDown(c.dispose);

    final ports = List<int>.generate(20, (i) => 1000 + i);
    final run = c.scan(
        host: '127.0.0.1', ports: ports, timeoutMs: 200, concurrency: 1);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    c.stop();
    await run;

    expect(c.status, ScanStatus.stopped);
    expect(c.scanned, lessThan(20));
  });
}
