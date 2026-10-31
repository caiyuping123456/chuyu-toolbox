/// 正则测试结果。
class RegexMatchItem {
  const RegexMatchItem({required this.text, required this.start, required this.end, required this.groups});
  final String text;
  final int start;
  final int end;
  final List<String?> groups;
}

class RegexResult {
  const RegexResult._({this.matches = const <RegexMatchItem>[], this.error});
  factory RegexResult.ok(List<RegexMatchItem> m) => RegexResult._(matches: m);
  factory RegexResult.fail(String msg) => RegexResult._(error: msg);
  final List<RegexMatchItem> matches;
  final String? error;
  bool get ok => error == null;
}

/// 正则匹配（global 标志支持）。
abstract final class RegexEngine {
  static RegexResult run(String pattern, String input,
      {bool global = true, bool multiline = false, bool caseSensitive = true}) {
    if (pattern.isEmpty) return RegexResult.fail('请输入正则表达式');
    RegExp re;
    try {
      re = RegExp(pattern,
          multiLine: multiline, caseSensitive: caseSensitive);
    } on FormatException catch (e) {
      return RegexResult.fail(e.message);
    }
    final out = <RegexMatchItem>[];
    try {
      for (final m in re.allMatches(input)) {
        out.add(RegexMatchItem(
          text: m.group(0) ?? '',
          start: m.start,
          end: m.end,
          groups: [for (var i = 1; i < m.groupCount + 1; i++) m.group(i)],
        ));
        if (!global) break;
      }
    } catch (e) {
      return RegexResult.fail('$e');
    }
    return RegexResult.ok(out);
  }
}
