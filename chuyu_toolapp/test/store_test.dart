import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/modules/http_test/models.dart';
import 'package:chuyu_toolapp/modules/http_test/store.dart';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('chuyu_store_test');
  });
  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  SavedRequest req(String name, [String url = 'https://a.com']) =>
      SavedRequest(name: name, method: 'GET', url: url);

  test('集合：创建 / 重命名 / 删除 / 保存与更新请求', () async {
    final s = HttpStore(baseDir: dir);
    await s.load();
    expect(s.collections, isEmpty);

    final c1 = s.createCollection('工作集合');
    s.createCollection('临时');
    expect(s.collections, hasLength(2));
    expect(s.collections.first.name, '工作集合'); // 新的在前

    s.renameCollection(c1.id, '日常');
    expect(s.collections.first.name, '日常');

    final r = req('登录接口', 'https://a.com/login');
    s.saveRequest(c1.id, r);
    expect(s.collections.first.items, hasLength(1));

    // 同 id 再保存 = 更新（upsert）
    r.name = '登录接口 v2';
    s.saveRequest(c1.id, r);
    expect(s.collections.first.items, hasLength(1));
    expect(s.collections.first.items.first.name, '登录接口 v2');

    s.deleteRequest(c1.id, r.id);
    expect(s.collections.first.items, isEmpty);

    s.deleteCollection(c1.id);
    expect(s.collections, hasLength(1));
    expect(s.collections.first.name, '临时');
  });

  test('历史：新记录在最前，上限 200，可清空', () async {
    final s = HttpStore(baseDir: dir);
    await s.load();

    for (var i = 0; i < 205; i++) {
      s.addHistory(HistoryEntry(
        time: DateTime(2026, 1, 1, 0, 0, i),
        request: req('r$i'),
        status: 200,
      ));
    }
    expect(s.history, hasLength(HttpStore.historyLimit));
    expect(s.history.first.request.name, 'r204'); // 最新的在最前
    expect(s.history.last.request.name, 'r5'); // 最早的被裁掉

    s.clearHistory();
    expect(s.history, isEmpty);
  });

  test('持久化：重启（新实例同目录）数据完好；损坏文件按空处理', () async {
    final s = HttpStore(baseDir: dir);
    await s.load();
    final c = s.createCollection('工作集合');
    s.saveRequest(c.id, req('登录接口', 'https://a.com/login'));
    s.addHistory(HistoryEntry(
        time: DateTime(2026, 10, 24, 14, 32),
        request: req('h1'),
        status: 404,
        durationMs: 12));

    // 模拟重启
    final s2 = HttpStore(baseDir: dir);
    await s2.load();
    expect(s2.collections, hasLength(1));
    expect(s2.collections.first.name, '工作集合');
    expect(s2.collections.first.items.first.url, 'https://a.com/login');
    expect(s2.history, hasLength(1));
    expect(s2.history.first.status, 404);
    expect(s2.history.first.time, DateTime(2026, 10, 24, 14, 32));

    // 损坏容错
    File('${dir.path}${Platform.pathSeparator}history.json')
        .writeAsStringSync('{不是合法JSON');
    final s3 = HttpStore(baseDir: dir);
    await s3.load();
    expect(s3.history, isEmpty);
    expect(s3.collections, hasLength(1)); // 另一文件不受影响
  });
}
