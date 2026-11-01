import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/main.dart';
import 'package:provider/provider.dart';
import 'package:chuyu_toolapp/modules/http_test/store.dart';
import 'package:chuyu_toolapp/shell/settings_store.dart';
import 'package:chuyu_toolapp/shell/app.dart';

void main() {
  late Directory storeDir;
  late Directory settingsDir;
  setUp(() {
    storeDir = Directory.systemTemp.createTempSync('chuyu_shell_store');
    HttpStore.debugBaseDir = storeDir;
    settingsDir = Directory.systemTemp.createTempSync('chuyu_shell_settings');
  });
  tearDown(() {
    HttpStore.debugBaseDir = null;
    if (storeDir.existsSync()) storeDir.deleteSync(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // 清掉默认存储的临时目录，保证各测试初始状态一致（历史为空）
    final fb = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}chuyu-toolbox-fallback');
    if (fb.existsSync()) fb.deleteSync(recursive: true);
    tester.view.physicalSize = const Size(960, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsStore>(
            create: (_) => SettingsStore(baseDir: settingsDir)..load()),
      ],
      child: ToolboxApp(registry: ToolboxAppBootstrap.registry),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> ctrlK(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('首页：介绍 / 搜索入口 / 快速入口 / 全部工具', (tester) async {
    await pumpApp(tester);
    expect(find.text('ChuYu 万能工具箱'), findsWidgets); // 品牌区 + 标题栏 + 首页
    expect(find.text('搜索工具、操作…'), findsOneWidget);
    expect(find.text('新建请求'), findsOneWidget); // 快速入口卡片
    expect(find.text('时间戳转换'), findsWidgets); // 侧栏 + 全部工具
    expect(find.text('10 个工具规划'), findsOneWidget);
    expect(find.text('10 个已启用'), findsOneWidget);
  });

  testWidgets('侧栏：进入 HTTP 模块页', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('HTTP 测试').first);
    await tester.pumpAndSettle();
    expect(find.text('模块 v1.0 · M3'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('侧栏：端口连通检测模块可进入', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('端口连通检测').first);
    await tester.pumpAndSettle();
    expect(find.text('模块 v1.0 · M5-2'), findsOneWidget);
  });

  testWidgets('侧栏：JSON 格式化模块可进入', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('JSON 格式化').first);
    await tester.pumpAndSettle();
    expect(find.text('模块 v1.0 · M5-3'), findsOneWidget);
  });

  testWidgets('侧栏：WebSocket 模块可进入', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('WebSocket 测试').first);
    await tester.pumpAndSettle();
    expect(find.text('模块 v1.0 · M5'), findsOneWidget);
  });

  testWidgets('快速入口深链接：请求历史 → 打开历史页签', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('请求历史'));
    await tester.pumpAndSettle();
    expect(find.text('模块 v1.0 · M3'), findsOneWidget);
    expect(find.text('暂无历史'), findsOneWidget); // 真实存储初始为空
    expect(find.text('默认集合'), findsNothing); // 集合页签未激活
  });

  testWidgets('全局搜索：Ctrl K 打开 / 过滤 / Enter 执行 / Esc 关闭', (tester) async {
    await pumpApp(tester);

    // Ctrl K 打开命令面板
    await ctrlK(tester);
    await tester.pumpAndSettle();
    expect(find.text('快捷入口'), findsOneWidget); // 分组头

    // 输入即时过滤
    await tester.enterText(find.byKey(const ValueKey('palette_input')), 'websock');
    await tester.pumpAndSettle();
    final list = find.byKey(const ValueKey('palette_list'));
    expect(
        find.descendant(of: list, matching: find.text('WebSocket 测试')),
        findsOneWidget);
    expect(
        find.descendant(of: list, matching: find.text('HTTP 测试')),
        findsNothing);

    // Enter 执行选中项（WebSocket → 进入模块）
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('模块 v1.0 · M5'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('快捷入口'), findsNothing); // 面板已关闭

    // Esc 关闭
    await ctrlK(tester);
    await tester.pumpAndSettle();
    expect(find.text('快捷入口'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('快捷入口'), findsNothing);
  });
}













