import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/modules/json_format/json_formatter.dart';

void main() {
  test('格式化：对象 / 数组 / 基础类型', () {
    final r = JsonFormatter.format('{"b":2,"a":[1,true,null]}');
    expect(r.ok, isTrue);
    expect(r.output, '{\n  "b": 2,\n  "a": [\n    1,\n    true,\n    null\n  ]\n}');
    expect(r.itemCount, 2);

    expect(JsonFormatter.format('[1,2,3]').output, '[\n  1,\n  2,\n  3\n]');
    expect(JsonFormatter.format('42').output, '42');
    expect(JsonFormatter.format('"hi"').output, '"hi"');
  });

  test('缩进 4 空格 / 排序键 / 压缩', () {
    final four = JsonFormatter.format('{"b":1,"a":2}', indent: 4);
    expect(four.output, '{\n    "b": 1,\n    "a": 2\n}');

    final sorted = JsonFormatter.format('{"b":1,"a":{"d":2,"c":3}}',
        sortKeys: true);
    expect(sorted.output,
        '{\n  "a": {\n    "c": 3,\n    "d": 2\n  },\n  "b": 1\n}');

    final mini = JsonFormatter.minify('{\n  "a": 1,\n  "b": [\n    2\n  ]\n}');
    expect(mini.output, '{"a":1,"b":[2]}');
  });

  test('非法 JSON：错误信息与行列号', () {
    final r = JsonFormatter.format('{\n  "a": 1,\n  "b": oops\n}');
    expect(r.ok, isFalse);
    expect(r.error, isNotEmpty);
    expect(r.line, 3);
    expect(r.column, isNotNull);
  });

  test('空输入 / 超大输入', () {
    final empty = JsonFormatter.format('   ');
    expect(empty.ok, isFalse);
    expect(empty.error, contains('请输入'));

    final big = '{"a":"${'x' * (JsonFormatter.maxBytes + 10)}"}';
    final r = JsonFormatter.format(big);
    expect(r.ok, isFalse);
    expect(r.error, contains('2 MB'));
  });

  test('校验 / 中文与转义保持', () {
    final ok = JsonFormatter.validate('{"名称":"张三","note":"a\\"b"}');
    expect(ok.ok, isTrue);
    expect(ok.output, contains('张三'));

    final bad = JsonFormatter.validate('{');
    expect(bad.ok, isFalse);
  });

  test('输出字节数正确（UTF-8）', () {
    final r = JsonFormatter.format('{"名":"张三"}');
    expect(r.outputBytes, utf8.encode(r.output!).length);
  });
}
