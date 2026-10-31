import 'package:flutter/material.dart';

import 'core/module_registry.dart';
import 'modules/http_test/http_test_module.dart';
import 'modules/json_format/json_format_module.dart';
import 'modules/port_scan/port_scan_module.dart';
import 'modules/websocket_test/websocket_test_module.dart';
import 'shell/app.dart';

void main() {
  runApp(const ToolboxAppBootstrap());
}

/// 组装模块注册表并启动壳（SPEC §5：壳读注册表渲染一切入口，模块只登记一行）。
class ToolboxAppBootstrap extends StatelessWidget {
  const ToolboxAppBootstrap({super.key});

  static final ModuleRegistry registry = ModuleRegistry(const [
    HttpTestModule(),
    WebSocketTestModule(),
    PortScanModule(),
    JsonFormatModule(),
    ...plannedModules,
  ]);

  @override
  Widget build(BuildContext context) {
    return ToolboxApp(registry: registry);
  }
}




