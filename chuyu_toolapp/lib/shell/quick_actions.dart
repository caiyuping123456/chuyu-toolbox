import 'package:flutter/material.dart';

import '../modules/http_test/http_test_module.dart'
    show HttpOpenIntent, HttpSideTab;
import 'app_state.dart';

/// 首页快速入口与全局搜索「快捷入口」分组共用的 4 个固定操作（SPEC §4.2 / §4.5）。
class QuickAction {
  const QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.run,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final void Function(AppState state) run;
}

void _openModule(AppState s) => s.openModule('http_test');
void _newRequest(AppState s) =>
    s.openModule('http_test', intent: const HttpOpenIntent(focusUrl: true));
void _openHistory(AppState s) => s.openModule('http_test',
    intent: const HttpOpenIntent(tab: HttpSideTab.history));
void _openCollections(AppState s) => s.openModule('http_test',
    intent: const HttpOpenIntent(tab: HttpSideTab.collections));

const quickActions = <QuickAction>[
  QuickAction(
      icon: Icons.public,
      title: 'HTTP 请求测试',
      subtitle: '打开 HTTP 测试模块',
      run: _openModule),
  QuickAction(
      icon: Icons.note_add_outlined,
      title: '新建请求',
      subtitle: '进入模块并聚焦 URL 输入',
      run: _newRequest),
  QuickAction(
      icon: Icons.history,
      title: '请求历史',
      subtitle: '查看最近发送的请求',
      run: _openHistory),
  QuickAction(
      icon: Icons.folder_open,
      title: '请求集合',
      subtitle: '管理已保存的请求',
      run: _openCollections),
];
