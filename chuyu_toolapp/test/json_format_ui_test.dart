import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/core/theme.dart';
import 'package:chuyu_toolapp/modules/json_format/ui/json_format_page.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('页面：格式化 / 压缩 / 校验 / 排序 / 清空 / 复制', (tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(wrap(const JsonFormatPage()));
    await tester.pump();

    await tester.enterText(
        find.byKey(const ValueKey('json_input')), '{"b":2,"a":1}');
    await tester.tap(find.byKey(const ValueKey('json_format')));
    await tester.pump();
    expect(find.textContaining('"a": 1'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('json_minify')));
    await tester.pump();
    expect(find.textContaining('{"b":2,"a":1}'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('json_sort')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('json_format')));
    await tester.pump();
    expect(find.textContaining('"a": 1'), findsWidgets);
    expect(find.textContaining('"b": 2'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('json_validate')));
    await tester.pump();
    expect(find.text('JSON 合法'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('json_copy')));
    await tester.pump();
    expect(copied, isNotNull);
    expect(copied, contains('"a": 1'));

    await tester.tap(find.byKey(const ValueKey('json_clear')));
    await tester.pump();
    expect(find.text('点击「格式化」查看结果'), findsOneWidget);
  });

  testWidgets('页面：非法 JSON 显示行号', (tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const JsonFormatPage()));
    await tester.pump();

    await tester.enterText(
        find.byKey(const ValueKey('json_input')), '{\n  "a": oops\n}');
    await tester.tap(find.byKey(const ValueKey('json_format')));
    await tester.pump();

    expect(find.text('JSON 不合法'), findsOneWidget);
    expect(find.textContaining('第 2 行'), findsOneWidget);
  });

  testWidgets('页面：示例可一键载入并格式化', (tester) async {
    tester.view.physicalSize = const Size(1100, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const JsonFormatPage()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('json_sample')));
    await tester.pump();
    expect(find.textContaining('"code": 0'), findsWidgets);
    expect(find.textContaining('张三'), findsWidgets);
  });
}
