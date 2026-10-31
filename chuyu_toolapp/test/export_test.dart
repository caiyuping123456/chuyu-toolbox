import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/core/export_service.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('chuyu_export');
    ExportService.baseDirOverride = dir;
  });
  tearDown(() {
    ExportService.baseDirOverride = null;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('导出：写入文件 / 文件名带时间戳 / 空内容报错', () async {
    final now = DateTime(2026, 11, 1, 12, 30, 0);
    final r1 = await ExportService.exportText('{"a":1}', 'json-x', 'json', now: now);
    expect(r1.ok, isTrue);
    expect(r1.path, endsWith('json-x_20261101-123000.json'));
    expect(File(r1.path!).readAsStringSync(), '{"a":1}');

    final r2 = await ExportService.exportText('again', 'json-x', 'json', now: now);
    expect(r2.path, endsWith('json-x_20261101-123000-1.json'));

    final empty = await ExportService.exportText('', 'x', 'txt');
    expect(empty.ok, isFalse);
    expect(empty.error, contains('内容为空'));
  });
}
