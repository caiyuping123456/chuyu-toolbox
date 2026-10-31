import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/modules/http_test/http_client.dart';
import 'package:chuyu_toolapp/modules/http_test/models.dart';
import 'package:chuyu_toolapp/modules/http_test/store.dart';
import 'package:chuyu_toolapp/modules/http_test/ui/body_editor.dart';
import 'package:chuyu_toolapp/modules/http_test/ui/http_test_page.dart';
import 'package:chuyu_toolapp/modules/http_test/ui/kv_editor.dart';
import 'package:chuyu_toolapp/modules/http_test/ui/response_view.dart';

class FakeSender extends HttpSender {
  FakeSender();

  int calls = 0;
  String lastMethod = '';

  @override
  Future<HttpResult> send(HttpRequestSpec spec) async {
    calls++;
    lastMethod = spec.method;
    return HttpResult(
      status: 200,
      phrase: 'OK',
      headers: {'content-type': 'application/json'},
      body: '{"message":"ok"}',
      durationMs: 5,
      sizeBytes: 42,
    );
  }
}

Widget wrap(Widget child) => MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(body: child),
    );

void main() {
  late Directory appStoreDir;
  setUp(() {
    appStoreDir = Directory.systemTemp.createTempSync('chuyu_app_store');
    HttpStore.debugBaseDir = appStoreDir;
  });
  tearDown(() {
    HttpStore.debugBaseDir = null;
    if (appStoreDir.existsSync()) appStoreDir.deleteSync(recursive: true);
  });

  testWidgets('KvEditor：新增行并回调', (tester) async {
    final entries = <KvEntry>[KvEntry(key: 'page', value: '1')];
    var changed = 0;
    await tester.pumpWidget(wrap(StatefulBuilder(
      builder: (context, setState) => SizedBox(
        width: 600,
        child: KvEditor(
          entries: entries,
          onChanged: () {
            changed++;
            setState(() {});
          },
        ),
      ),
    )));

    expect(find.text('page'), findsOneWidget);
    await tester.tap(find.text('新增一行'));
    await tester.pump();
    expect(entries, hasLength(2));
    expect(changed, greaterThanOrEqualTo(1));
  });

  testWidgets('BodyEditor：切到 raw 并编辑内容同步到模型', (tester) async {
    final body = HttpBodySpec();
    final raw = TextEditingController();
    await tester.pumpWidget(wrap(StatefulBuilder(
      builder: (context, setState) => SizedBox(
        width: 600,
        child: BodyEditor(
          body: body,
          rawController: raw,
          onChanged: () => setState(() {}),
        ),
      ),
    )));

    await tester.tap(find.text('raw'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '{"a":1}');
    await tester.pump();
    expect(body.kind, BodyKind.raw);
    expect(body.rawContent, '{"a":1}');
  });

  testWidgets('ResponseView：成功（Pretty 高亮）/ 失败 / 发送中', (tester) async {
    final ok = HttpResult(
      status: 200,
      phrase: 'OK',
      headers: {'content-type': 'application/json'},
      body: '{"code":0,"message":"ok"}',
      durationMs: 42,
      sizeBytes: 123,
    );

    await tester.pumpWidget(wrap(ResponseView(result: ok, sending: false)));
    expect(find.text('200 OK'), findsOneWidget);
    expect(find.text('42 ms'), findsOneWidget);
    expect(
        find.textContaining('"code"', findRichText: true), findsOneWidget);

    // Headers 页签
    await tester.tap(find.text('Headers'));
    await tester.pump();
    expect(find.text('application/json'), findsOneWidget);

    // 失败态
    await tester.pumpWidget(wrap(
        ResponseView(result: HttpResult(error: '连接失败：拒绝'), sending: false)));
    expect(find.text('请求失败'), findsOneWidget);
    expect(find.textContaining('连接失败'), findsOneWidget);

    // 发送中
    await tester.pumpWidget(
        wrap(const ResponseView(result: null, sending: true)));
    expect(find.text('发送中…'), findsOneWidget);
  });

  testWidgets('页面：点击发送与 Ctrl Enter → 展示 200 与 Pretty（注入 FakeSender）',
      (tester) async {
    final sender = FakeSender();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: HttpTestPage(sender: sender),
      ),
    ));

    // 点击发送
    await tester.enterText(find.byKey(const ValueKey('url_field')),
        'https://example.com/api');
    await tester.tap(find.text('发送'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(sender.calls, 1);
    expect(find.text('200 OK'), findsOneWidget);
    expect(find.textContaining('"message"', findRichText: true), findsWidgets);

    // Params 表编辑 → URL 双向同步
    await tester.enterText(
        find.byKey(const ValueKey('url_field')), 'https://example.com/a?x=9');
    await tester.pump();
    expect(find.text('x'), findsWidgets); // Params 表出现该参数

    // Ctrl Enter 再次发送（焦点在 URL 输入框）
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(sender.calls, 2);
    expect(sender.lastMethod, 'GET');
    expect(find.text('200 OK'), findsOneWidget);
  });

  testWidgets('M3 持久化：保存到集合 / 历史记录 / 过滤 / 载入回填 / 重启完好',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('chuyu_m3');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final store = HttpStore(baseDir: dir);
    final sender = FakeSender();
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(body: HttpTestPage(sender: sender, store: store)),
    ));
    await tester.pumpAndSettle(); // 加载存储 → 自动建「默认集合」
    // ignore: avoid_print
    print('M3-STEP1 store-loaded');

    // 发送 → 历史自动记录 1 条
    await tester.enterText(
        find.byKey(const ValueKey('url_field')), 'https://example.com/api');
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(store.history, hasLength(1));
    // ignore: avoid_print
    print('M3-STEP2 sent');

    // 保存到集合
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('save_name_field')), '登录接口');
    await tester.tap(find.text('确定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.collections.first.items, hasLength(1));
    expect(find.text('登录接口'), findsOneWidget); // 侧栏集合项
    // ignore: avoid_print
    print('M3-STEP3 saved');

    // 历史 + 本地过滤
    await tester.tap(find.text('历史'));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('M3-STEP4 history-open');
    final side = find.byKey(const ValueKey('module_side'));
    expect(find.descendant(of: side, matching: find.textContaining('example.com')),
        findsWidgets);
    await tester.enterText(find.byKey(const ValueKey('side_search')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.descendant(of: side, matching: find.textContaining('example.com')),
        findsNothing);
    expect(find.text('暂无历史'), findsOneWidget); // 过滤后空态

    // 回到集合，载入回填
    await tester.tap(find.text('集合'));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('M3-STEP5 back-to-collections');
    await tester.enterText(find.byKey(const ValueKey('side_search')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('登录接口').first);
    await tester.pumpAndSettle();
    final urlField =
        tester.widget<TextField>(find.byKey(const ValueKey('url_field')));
    expect((urlField.controller as TextEditingController).text,
        'https://example.com/api');
    expect(find.textContaining('已载入'), findsOneWidget);

    // 模拟重启：新 store 同目录数据完好
    final store2 = HttpStore(baseDir: dir);
    await store2.load();
    expect(store2.collections.first.items, hasLength(1));
    expect(store2.collections.first.items.first.name, '登录接口');
    expect(store2.history, hasLength(1));
  });
}


