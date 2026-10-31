import 'dart:convert';

/// JSON 处理结果：成功时 [output] 有值，失败时 [error] 有值（SPEC §5.3）。
class JsonFormatResult {
  const JsonFormatResult._({
    this.output,
    this.error,
    this.line,
    this.column,
    this.inputBytes = 0,
    this.outputBytes = 0,
    this.itemCount = 0,
  });

  factory JsonFormatResult.ok(String output, {int itemCount = 0}) {
    return JsonFormatResult._(
      output: output,
      inputBytes: 0,
      outputBytes: utf8.encode(output).length,
      itemCount: itemCount,
    );
  }

  factory JsonFormatResult.fail(String error,
      {int? line, int? column, int inputBytes = 0}) {
    return JsonFormatResult._(
      error: error,
      line: line,
      column: column,
      inputBytes: inputBytes,
    );
  }

  final String? output;
  final String? error;
  final int? line;
  final int? column;
  final int inputBytes;
  final int outputBytes;
  final int itemCount;

  bool get ok => error == null;
}

/// JSON 格式化 / 压缩 / 校验（纯 dart:convert，无第三方依赖）。
abstract final class JsonFormatter {
  /// 与 HTTP 模块一致：Pretty 上限 2 MB（SPEC §6.2 / §10）。
  static const int maxBytes = 2 * 1024 * 1024;

  static String? _clean(String input) {
    final t = input.trim();
    return t.isEmpty ? null : t;
  }

  /// 格式化。indent 为空格数（2 / 4），sortKeys 时按字典序输出对象键。
  static JsonFormatResult format(
    String input, {
    int indent = 2,
    bool sortKeys = false,
  }) {
    final src = _clean(input);
    if (src == null) return JsonFormatResult.fail('请输入 JSON 内容');
    final bytes = utf8.encode(src).length;
    if (bytes > maxBytes) {
      return JsonFormatResult.fail(
          '内容超过 ${maxBytes ~/ (1024 * 1024)} MB 上限（当前 ${_mb(bytes)}）',
          inputBytes: bytes);
    }
    try {
      final decoded = jsonDecode(src);
      final normalized = sortKeys ? _sort(decoded) : decoded;
      final pretty = indent == 0
          ? jsonEncode(normalized)
          : JsonEncoder.withIndent(' ' * indent).convert(normalized);
      return JsonFormatResult.ok(pretty,
          itemCount: _count(normalized));
    } on FormatException catch (e) {
      final pos = _locate(src, e);
      return JsonFormatResult.fail(
        _describe(e),
        line: pos?.$1,
        column: pos?.$2,
        inputBytes: bytes,
      );
    } catch (e) {
      return JsonFormatResult.fail('$e', inputBytes: bytes);
    }
  }

  /// 压缩为单行（移除缩进与空白）。
  static JsonFormatResult minify(String input) =>
      format(input, indent: 0);

  /// 只校验，不产出文本。
  static JsonFormatResult validate(String input) {
    final r = format(input);
    if (!r.ok) return r;
    return JsonFormatResult.ok(r.output!);
  }

  /// 从错误信息与原文推算行列（1 基）；无法定位时返回 null。
  static (int, int)? _locate(String src, FormatException e) {
    int? offset = e.offset;
    if (offset == null) {
      final m = RegExp(r'at character (\d+)').firstMatch(e.message);
      if (m != null) offset = int.tryParse(m.group(1)!);
    }
    int? start;
    if (offset == null) {
      final m = RegExp(r'\(at line (\d+) column (\d+)\)').firstMatch(e.message);
      if (m != null) {
        return (int.parse(m.group(1)!), int.parse(m.group(2)!));
      }
      return null;
    }
    start = offset.clamp(0, src.length);
    var line = 1;
    var col = 1;
    for (var i = 0; i < start; i++) {
      if (src[i] == '\n') {
        line++;
        col = 1;
      } else {
        col++;
      }
    }
    return (line, col);
  }

  static String _describe(FormatException e) {
    var msg = e.message;
    msg = msg.replaceAll(RegExp(r'^FormatException:\s*'), '');
    return msg.isEmpty ? '不是合法的 JSON' : msg;
  }

  static int _count(Object? value) {
    if (value is List) return value.length;
    if (value is Map) return value.length;
    return 0;
  }

  /// 递归按字典序重排对象键（数组顺序保持不变）。
  static Object? _sort(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => '$k').toList()..sort();
      final out = <String, Object?>{};
      for (final k in keys) {
        out[k] = _sort(value[k]);
      }
      return out;
    }
    if (value is List) return value.map(_sort).toList();
    return value;
  }

  static String _mb(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }
}
