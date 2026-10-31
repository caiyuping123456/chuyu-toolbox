import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/core/theme.dart';
import 'package:chuyu_toolapp/modules/websocket_test/ui/websocket_test_page.dart';
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
  testWidgets('页面：连接 / 发送 / 接收 / 清空 / 断开', (tester) async {
    final connector = FakeWsConnector();
    tester.view.physicalSize = const Size(960, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: WebSocketTestPage(connector: connector)),
    ));
    await tester.pump();

    await tester.enterText(
        find.byKey(const ValueKey('ws_url_field')), 'ws://test.local');
    await tester.tap(find.text('连接'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('已连接'), findsOneWidget);
    expect(connector.lastUrl, 'ws://test.local');

    final conn = connector.connection!;
    await tester.enterText(
        find.byKey(const ValueKey('ws_message_field')), 'hello');
    await tester.tap(find.text('发送'));
    await tester.pump();
    expect(conn.sent, <String>['hello']);
    expect(find.text('hello'), findsOneWidget);

    conn.emit('world');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('world'), findsOneWidget);

    // Ctrl Enter 发送
    await tester.enterText(
        find.byKey(const ValueKey('ws_message_field')), 'bye');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(conn.sent, <String>['hello', 'bye']);

    await tester.tap(find.byKey(const ValueKey('ws_clear')));
    await tester.pump();
    expect(find.text('连接后开始收发消息'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ws_connect')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('已断开'), findsOneWidget);
    expect(conn.closed, isTrue);
  });

  testWidgets('页面：非法 URL 显示错误', (tester) async {
    final connector = FakeWsConnector();
    tester.view.physicalSize = const Size(960, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: WebSocketTestPage(connector: connector)),
    ));
    await tester.pump();

    await tester.enterText(
        find.byKey(const ValueKey('ws_url_field')), 'http://example.com');
    await tester.tap(find.text('连接'));
    await tester.pump();

    expect(find.text('连接失败'), findsOneWidget);
    expect(find.textContaining('ws://'), findsWidgets);
    expect(connector.lastUrl, isNull);
  });
}




