import 'dart:convert';

/// Base64 编解码结果。
class Base64Result {
  const Base64Result._({this.output, this.error});

  factory Base64Result.ok(String out) => Base64Result._(output: out);
  factory Base64Result.fail(String msg) => Base64Result._(error: msg);

  final String? output;
  final String? error;
  bool get ok => error == null;
}

/// 文本 ↔ Base64（UTF-8）；支持标准与 URL-Safe 字母表。
abstract final class Base64CodecX {
  static Base64Result encode(String text, {bool urlSafe = false}) {
    final bytes = utf8.encode(text);
    var out = base64Encode(bytes);
    if (urlSafe) out = out.replaceAll('+', '-').replaceAll('/', '_');
    return Base64Result.ok(out);
  }

  /// 自动识别 URL-Safe；容错空格。支持纯 Base64 文本输入。
  static Base64Result decode(String text) {
    var s = text.trim().replaceAll(RegExp(r'\s'), '');
    if (s.isEmpty) return Base64Result.fail('请输入 Base64 内容');
    if (s.contains('-') || s.contains('_')) {
      s = s.replaceAll('-', '+').replaceAll('_', '/');
    }
    // 补齐 padding
    final pad = s.length % 4;
    if (pad == 2) s = '$s==';
    if (pad == 3) s = '$s=';
    if (pad == 1) return Base64Result.fail('Base64 长度不合法');
    try {
      final bytes = base64Decode(s);
      return Base64Result.ok(utf8.decode(bytes, allowMalformed: true));
    } on FormatException catch (e) {
      return Base64Result.fail('不是合法的 Base64：${e.message}');
    }
  }
}
