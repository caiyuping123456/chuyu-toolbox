import 'package:flutter/material.dart';

import '../toolbox_module.dart';
import 'ui/port_scan_page.dart';

/// 端口连通检测模块（M5-2）。
class PortScanModule extends ToolboxModule {
  const PortScanModule();

  @override
  String get id => 'port_scan';
  @override
  String get name => '端口连通检测';
  @override
  String get category => '网络测试';
  @override
  String get summary => 'TCP 端口连通性探测';
  @override
  List<String> get keywords => const ['port', 'tcp', '端口', '扫描', '连通'];
  @override
  String get version => '1.0.0';
  @override
  bool get enabled => true;
  @override
  IconData get icon => Icons.network_check;

  @override
  Widget buildPage(BuildContext context, {Object? intent}) {
    return const PortScanPage();
  }
}
