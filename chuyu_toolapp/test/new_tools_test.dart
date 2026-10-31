import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/modules/base64_codec/base64_codec.dart';
import 'package:chuyu_toolapp/modules/hash_calc/hash_service.dart';
import 'package:chuyu_toolapp/modules/regex_test/regex_engine.dart';
import 'package:chuyu_toolapp/modules/timestamp/time_conv.dart';
import 'package:chuyu_toolapp/modules/uuid_gen/uuid_service.dart';

void main() {
  group('Base64', () {
    test('编码 / 解码 / URL-Safe / 中文', () {
      final e1 = Base64CodecX.encode('ChuYu 工具箱');
      expect(e1.ok, isTrue);
      final d1 = Base64CodecX.decode(e1.output!);
      expect(d1.output, 'ChuYu 工具箱');

      final e2 = Base64CodecX.encode('a+b/c?', urlSafe: true);
      expect(e2.output, isNot(contains('+')));
      expect(e2.output, isNot(contains('/')));
      final d2 = Base64CodecX.decode(e2.output!);
      expect(d2.output, 'a+b/c?');
    });

    test('非法输入', () {
      expect(Base64CodecX.decode('').ok, isFalse);
      expect(Base64CodecX.decode('!!!!').ok, isFalse);
    });
  });

  group('时间戳', () {
    test('秒 / 毫秒 → 日期', () {
      final r = TimeConverter.fromUnix('1792948200');
      expect(r.ok, isTrue);
      expect(r.output, contains('本地'));
    expect(r.output, contains('UTC'));
    });

    test('日期 → 秒 / 毫秒', () {
      final r = TimeConverter.toUnix('2026-10-31 14:30:00');
      expect(r.output, contains('毫秒'));


      final sec = int.parse(
          r.output!.split('\n').firstWhere((l) => l.startsWith('秒')).split('：').last);
      final back = TimeConverter.fromUnix('$sec');
      expect(back.output, contains('14:30:00'), reason: back.output ?? '');
    });

    test('非法输入', () {
      expect(TimeConverter.fromUnix('abc').ok, isFalse);
      expect(TimeConverter.toUnix('not a date').ok, isFalse);
    });
  });

  group('正则', () {
    test('匹配 / 分组 / 非全局', () {
      final r = RegexEngine.run(r'(\w+)@(\w+)', 'a@b c@d');
      expect(r.ok, isTrue);
      expect(r.matches, hasLength(2));
      expect(r.matches.first.groups, <String?>['a', 'b']);

      final one = RegexEngine.run(r'\w', 'abc', global: false);
      expect(one.matches, hasLength(1));
    });

    test('非法正则', () {
      final r = RegexEngine.run('[unclosed', 'x');
      expect(r.ok, isFalse);
    });
  });

  group('哈希', () {
    test('已知值', () {
      expect(HashService.md5('hello'),
          '5d41402abc4b2a76b9719d911017c592');
      expect(HashService.sha1('hello'),
          'aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d');
      expect(HashService.sha256('hello').length, 64);
      expect(HashService.sha512('hello').length, 128);
      expect(HashService.all('x'), hasLength(4));
    });
  });

  group('UUID', () {
    test('v4 格式 / 唯一 / 选项', () {
      final a = UuidService.v4();
      expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(UuidService.v4(), isNot(a));

      final ids = UuidService.generate(10);
      expect(ids.toSet(), hasLength(10));

      final noDash = UuidService.v4().replaceAll('-', '');
      expect(noDash.length, 32);
    });
  });
}



