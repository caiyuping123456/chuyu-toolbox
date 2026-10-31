import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/core/theme.dart';
import 'package:chuyu_toolapp/modules/port_scan/port_scanner.dart';
import 'package:chuyu_toolapp/modules/port_scan/ui/port_scan_page.dart';

class FakeProbe implements PortProbe {
  @override
  Future<PortResult> probe(String host, int port, Duration timeout) async {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final open = port == 80;
    return PortResult(
      port: port,
      state: open ? PortState.open : PortState.closed,
      latencyMs: open ? 4 : 0,
    );
  }
}

Widget wrap(Widget child) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('页面：扫描 / 统计 / 结果 / 清空', (tester) async {
    tester.view.physicalSize = const Size(960, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(PortScanPage(probe: FakeProbe())));
    await tester.pump();

    await tester.enterText(
        find.byKey(const ValueKey('port_host_field')), '127.0.0.1');
    await tester.enterText(
        find.byKey(const ValueKey('port_ports_field')), '80,443,8080');
    await tester.tap(find.text('开始扫描'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('开放 1'), findsOneWidget);
    expect(find.text('关闭 2'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
    expect(find.text('HTTP'), findsOneWidget); // 80 的服务名
    expect(find.text('80'), findsOneWidget); // 结果行端口
    expect(find.text('4 ms'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('port_clear')));
    await tester.pump();
    expect(find.text('输入主机与端口后开始扫描'), findsOneWidget);
  });

  testWidgets('页面：非法端口提示且不启动扫描', (tester) async {
    tester.view.physicalSize = const Size(960, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(PortScanPage(probe: FakeProbe())));
    await tester.pump();

    await tester.enterText(
        find.byKey(const ValueKey('port_ports_field')), 'abc');
    await tester.tap(find.text('开始扫描'));
    await tester.pump();

    expect(find.textContaining('无法识别'), findsOneWidget);
    expect(find.text('待扫描'), findsOneWidget);
  });
}

