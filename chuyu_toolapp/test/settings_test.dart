import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chuyu_toolapp/core/theme.dart';
import 'package:chuyu_toolapp/shell/settings_page.dart';
import 'package:chuyu_toolapp/shell/settings_store.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('chuyu_settings');
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsStore>(
              create: (_) => SettingsStore(baseDir: dir)..load()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          darkTheme: buildAppTheme(dark: true),
          home: Scaffold(body: child),
        ),
      );

  test('SettingsStore：默认值 / 持久化 / 重启完好 / 损坏容错', () async {
    final s = SettingsStore(baseDir: dir);
    await s.load();
    expect(s.dark, isFalse);
    expect(s.defaultTimeoutMs, 30000);
    expect(s.historyLimit, 200);

    s.setDark(true);
    s.setDefaultTimeout(60);
    s.setHistoryLimit(500);
    s.setFollowRedirects(false);

    final s2 = SettingsStore(baseDir: dir);
    await s2.load();
    expect(s2.dark, isTrue);
    expect(s2.defaultTimeoutMs, 60000);
    expect(s2.historyLimit, 500);
    expect(s2.followRedirects, isFalse);

    // 损坏容错
    File('${dir.path}${Platform.pathSeparator}settings.json')
        .writeAsStringSync('{bad json');
    final s3 = SettingsStore(baseDir: dir);
    await s3.load();
    expect(s3.dark, isFalse); // 回默认
  });

  testWidgets('设置页：切换深色 / 改超时 / 改历史上限', (tester) async {
    await tester.pumpWidget(wrap(const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('setting_dark')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('setting_timeout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60 秒').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('setting_history')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('500 条').last);
    await tester.pumpAndSettle();

    // 验证落盘
    final f = File('${dir.path}${Platform.pathSeparator}settings.json');
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    expect(json['dark'], isTrue);
    expect(json['defaultTimeoutMs'], 60000);
    expect(json['historyLimit'], 500);
  });
}
