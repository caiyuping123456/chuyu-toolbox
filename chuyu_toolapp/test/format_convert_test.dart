import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/modules/format_convert/format_converter.dart';

void main() {
  test('JSON → YAML', () {
    final r = FormatConverter.convert('{"name":"ChuYu","count":9}', Fmt.json, Fmt.yaml);
    expect(r.ok, isTrue);
    expect(r.output, contains('name: ChuYu'));
    expect(r.output, contains('count: 9'));
  });

  test('YAML → JSON', () {
    final r = FormatConverter.convert('name: ChuYu\ncount: 9', Fmt.yaml, Fmt.json);
    expect(r.ok, isTrue);
    expect(r.output, contains('"name": "ChuYu"'));
    expect(r.output, contains('"count": 9'));
  });

  test('JSON → CSV（对象数组）', () {
    final r = FormatConverter.convert('[{"a":1,"b":"x"},{"a":2,"b":"y"}]', Fmt.json, Fmt.csv);
    expect(r.ok, isTrue);
    final lines = r.output!.split('\n');
    expect(lines.first, 'a,b');
    expect(lines[1], '1,x');
  });

  test('CSV → JSON', () {
    final r = FormatConverter.convert('a,b\n1,x\n2,y', Fmt.csv, Fmt.json);
    expect(r.ok, isTrue);
    expect(r.output, contains('"a": "1"'));
    expect(r.output, contains('"b": "y"'));
  });

  test('XML → JSON / JSON → XML', () {
    final toJ = FormatConverter.convert('<root><name>ChuYu</name></root>', Fmt.xml, Fmt.json);
    expect(toJ.ok, isTrue);
    expect(toJ.output, contains('"name": "ChuYu"'));

    final toX = FormatConverter.convert('{"name":"ChuYu"}', Fmt.json, Fmt.xml);
    expect(toX.ok, isTrue);
    expect(toX.output, contains('<name>ChuYu</name>'));
  });

  test('排序键', () {
    final r = FormatConverter.convert('{"b":1,"a":2}', Fmt.json, Fmt.json, sortKeys: true);
    expect(r.ok, isTrue);
    expect(r.output!.indexOf('"a"'), lessThan(r.output!.indexOf('"b"')));
  });

  test('非法输入 / 空输入', () {
    expect(FormatConverter.convert('', Fmt.json, Fmt.yaml).ok, isFalse);
    expect(FormatConverter.convert('{bad', Fmt.json, Fmt.yaml).ok, isFalse);
  });

  test('CSV 非对象数组报错', () {
    final r = FormatConverter.convert('[1,2,3]', Fmt.json, Fmt.csv);
    expect(r.ok, isFalse);
    expect(r.error, contains('对象数组'));
  });
}
