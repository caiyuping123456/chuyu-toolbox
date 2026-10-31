/// 时间戳 / 日期互转结果。
class TimeConvResult {
  const TimeConvResult._({this.output, this.error});

  factory TimeConvResult.ok(String out) => TimeConvResult._(output: out);
  factory TimeConvResult.fail(String msg) => TimeConvResult._(error: msg);

  final String? output;
  final String? error;
  bool get ok => error == null;
}

/// Unix 秒 / 毫秒 ↔ 本地与 UTC 日期时间。
abstract final class TimeConverter {
  static String fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final w = names[dt.weekday - 1];
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)} $w';
  }

  /// 时间戳 → 日期：自动识别 秒(10位) / 毫秒(13位) / 微秒(16位)。
  static TimeConvResult fromUnix(String input) {
    final s = input.trim();
    if (s.isEmpty) return TimeConvResult.fail('请输入时间戳');
    final v = int.tryParse(s);
    if (v == null) return TimeConvResult.fail('请输入纯数字时间戳');
    final digits = s.replaceFirst(RegExp(r'^-'), '').length;
    DateTime dt;
    try {
      dt = switch (digits) {
        <= 11 => DateTime.fromMillisecondsSinceEpoch(v * 1000),
        <= 14 => DateTime.fromMillisecondsSinceEpoch(v),
        _ => DateTime.fromMillisecondsSinceEpoch((v / 1000).round()),
      };
    } catch (_) {
      return TimeConvResult.fail('时间戳超出可表示范围');
    }
    final utc = dt.toUtc();
    return TimeConvResult.ok(
        '本地：${fmt(dt)}\nUTC　：${fmt(utc)}\nISO  ：${dt.toIso8601String()}');
  }

  /// 日期 → 时间戳：支持 `2026-10-31 14:30` 与 ISO 8601。
  static TimeConvResult toUnix(String input) {
    final s = input.trim();
    if (s.isEmpty) return TimeConvResult.fail('请输入日期时间');
    final dt = DateTime.tryParse(s) ?? _tryFlexible(s);
    if (dt == null) return TimeConvResult.fail('无法解析日期：$s');
    final seconds = dt.millisecondsSinceEpoch ~/ 1000;
    return TimeConvResult.ok(
        '秒　　：$seconds\n毫秒：${dt.millisecondsSinceEpoch}');
  }

  static DateTime? _tryFlexible(String s) {
    final m = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})'
            r'(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$')
        .firstMatch(s);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4) ?? '0'),
      int.parse(m.group(5) ?? '0'),
      int.parse(m.group(6) ?? '0'),
    );
  }

  static String nowAll() {
    final n = DateTime.now();
    return '本地：${fmt(n)}\n秒　　：${n.millisecondsSinceEpoch ~/ 1000}\n'
        '毫秒：${n.millisecondsSinceEpoch}';
  }
}


