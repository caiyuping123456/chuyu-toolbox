import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/modules/websocket_test/ws_client.dart';

class FakeWsConnection implements WsConnection {
  final StreamController<Object?> _incoming =
      StreamController<Object?>.broadcast();
  final List<String> sent = <String>[];
  bool closed = false;

  @override
  Stream<Object?> get stream => _incoming.stream;

  @override
  void send(String text) => sent.add(text);

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) await _incoming.close();
  }

  void emit(Object? data) {
    if (!_incoming.isClosed) _incoming.add(data);
  }

  void serverClose() {
    if (!_incoming.isClosed) _incoming.close();
  }
}

class FakeWsConnector implements WsConnector {
  FakeWsConnection? connection;
  String? lastUrl;

  @override
  Future<WsConnection> connect(String url) async {
    lastUrl = url;
    connection = FakeWsConnection();
    return connection!;
  }
}

void main() {
  test('连接 / 发送 / 接收 / 断开', () async {
    final connector = FakeWsConnector();
    final c = WsController(connector: connector);
    addTearDown(c.dispose);

    await c.connect('ws://test.local');
    expect(c.status, WsStatus.connected);
    expect(connector.lastUrl, 'ws://test.local');
    expect(c.log.any((e) => e.text.contains('已连接')), isTrue);

    c.send('hello');
    expect(connector.connection!.sent, <String>['hello']);
    expect(c.log.last.direction, WsDirection.sent);
    expect(c.log.last.text, 'hello');

    connector.connection!.emit('world');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.log.last.direction, WsDirection.received);
    expect(c.log.last.text, 'world');

    await c.disconnect();
    expect(c.status, WsStatus.closed);
    expect(connector.connection!.closed, isTrue);
    expect(c.log.last.text, '已断开连接');
  });

  test('非法 URL → 失败状态与错误日志', () async {
    final c = WsController(connector: FakeWsConnector());
    addTearDown(c.dispose);

    await c.connect('http://not-a-websocket');
    expect(c.status, WsStatus.error);
    expect(c.log.last.direction, WsDirection.system);
    expect(c.log.last.error, isTrue);
    expect(c.log.last.text, contains('ws://'));
  });

  test('服务端关闭 → 已断开', () async {
    final connector = FakeWsConnector();
    final c = WsController(connector: connector);
    addTearDown(c.dispose);

    await c.connect('ws://test.local');
    connector.connection!.serverClose();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.status, WsStatus.closed);
    expect(c.log.last.text, contains('服务端已关闭'));
  });

  test('清空日志', () async {
    final connector = FakeWsConnector();
    final c = WsController(connector: connector);
    addTearDown(c.dispose);

    await c.connect('ws://test.local');
    c.send('a');
    expect(c.log, isNotEmpty);
    c.clear();
    expect(c.log, isEmpty);
  });

  test('IoWsConnector：本地回环真实收发', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sub = server.listen((req) async {
      final ws = await WebSocketTransformer.upgrade(req);
      ws.listen((data) => ws.add('echo:$data'));
    });
    final c = WsController();
    addTearDown(() async {
      c.dispose();
      await sub.cancel();
      await server.close(force: true);
    });

    await c.connect('ws://127.0.0.1:${server.port}');
    expect(c.status, WsStatus.connected);
    c.send('hi');

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (c.log.where((e) => e.direction == WsDirection.received).isEmpty &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(c.log.where((e) => e.direction == WsDirection.received), isNotEmpty);
    expect(c.log.last.text, 'echo:hi');

    await c.disconnect();
    expect(c.status, WsStatus.closed);
  });
}
