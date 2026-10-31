import 'package:flutter/material.dart';

/// 模块抽象接口（SPEC §5.1）。
///
/// 新增模块三步：`modules/<id>/` 建目录 → 实现本接口 → 注册表加一行；
/// 侧栏 / 首页 / 全局搜索 / 模块管理全部由注册表自动驱动。
abstract class ToolboxModule {
  const ToolboxModule();

  String get id; // 如 "http_test"
  String get name; // 如 "HTTP 测试"
  String get category; // 如 "网络测试"
  String get summary; // 一句话说明（首页 / 搜索展示）
  List<String> get keywords => const <String>[]; // 搜索关键词
  String get version; // 如 "1.0.0"；二期模块返回 "二期"
  bool get enabled => true; // 二期模块为 false，入口自动置灰
  IconData get icon;

  /// intent：深链接状态（如 HTTP 模块的「聚焦 URL / 打开集合或历史页签」），
  /// 由首页快速入口与全局搜索传入，可为 null。
  Widget buildPage(BuildContext context, {Object? intent});
}
