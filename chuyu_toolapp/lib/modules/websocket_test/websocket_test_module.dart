import 'package:flutter/material.dart';

import '../toolbox_module.dart';
import 'ui/websocket_test_page.dart';

/// 二期首个功能模块：WebSocket 测试（M5-1）。
class WebSocketTestModule extends ToolboxModule {
  const WebSocketTestModule();

  @override
  String get id => 'ws_test';
  @override
  String get name => 'WebSocket 测试';
  @override
  String get category => '网络测试';
  @override
  String get summary => '长连接收发与调试';
  @override
  List<String> get keywords => const ['ws', 'websocket', '长连接', '实时'];
  @override
  String get version => '1.0.0';
  @override
  bool get enabled => true;
  @override
  IconData get icon => Icons.settings_input_antenna;

  @override
  Widget buildPage(BuildContext context, {Object? intent}) {
    return const WebSocketTestPage();
  }
}
