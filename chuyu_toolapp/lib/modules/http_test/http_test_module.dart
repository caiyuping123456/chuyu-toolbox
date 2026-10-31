import 'package:flutter/material.dart';

import '../toolbox_module.dart';
import 'ui/http_test_page.dart';

/// 模块侧栏页签。
enum HttpSideTab { collections, history }

/// 深链接状态：首页快速入口 / 全局搜索可指定打开的页签或聚焦 URL（SPEC §4.3）。
class HttpOpenIntent {
  const HttpOpenIntent({this.tab, this.focusUrl = false});

  final HttpSideTab? tab;
  final bool focusUrl;
}

/// 本期唯一功能模块：HTTP 请求测试（轻量版 Postman）。
/// M1 交付工作区结构 + 深链接；发送/持久化在 M2 / M3 实现。
class HttpTestModule extends ToolboxModule {
  const HttpTestModule();

  @override
  String get id => 'http_test';
  @override
  String get name => 'HTTP 测试';
  @override
  String get category => '网络测试';
  @override
  String get summary => '发起 HTTP 请求并查看响应';
  @override
  List<String> get keywords =>
      const ['http', 'https', 'api', 'postman', '请求', '接口'];
  @override
  String get version => '1.0.0';
  @override
  IconData get icon => Icons.public;

  @override
  Widget buildPage(BuildContext context, {Object? intent}) {
    return HttpTestPage(
      key: const ValueKey('http_test_page'),
      intent: intent is HttpOpenIntent ? intent : null,
    );
  }
}
