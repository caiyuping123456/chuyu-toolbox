import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// JSON / XML 的 Pretty 化与语法着色（SPEC §6.2 / §7.3）。
/// Pretty 上限 2 MB，超过后界面提示切换 Raw。
abstract final class BodyFormatter {
  static const int prettyLimitBytes = 2 * 1024 * 1024;

  /// 尝试 JSON：成功返回 (pretty, isJson)，失败返回 null。
  static String? tryPrettyJson(String raw) {
    if (raw.trim().isEmpty) return null;
    final first = raw.trimLeft()[0];
    if (first != '{' && first != '[') return null;
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return null;
    }
  }

  /// 简单 XML 缩进（按标签层级换行缩进）。
  static String prettyXml(String raw) {
    final s = raw.replaceAll('>', '>\n');
    final lines = s.split('\n');
    final buf = StringBuffer();
    var depth = 0;
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('</')) depth = (depth - 1).clamp(0, 1 << 31);
      buf.writeln('${'  ' * depth}$line');
      final isClose = line.endsWith('/>') || line.startsWith('</');
      final open = '<'.allMatches(line).length;
      final close = '</'.allMatches(line).length + (isClose ? 1 : 0);
      final selfClose = line.endsWith('/>');
      if (!selfClose && open > close) depth++;
    }
    return buf.toString().trimRight();
  }

  /// 把 pretty 文本转为带语法着色的 TextSpan（键紫 / 字符串绿 / 数字橙 / 标点灰）。
  static TextSpan highlight(String pretty, BuildContext context) {
    final base = AppTypography.code.copyWith(fontSize: 11.5);
    final tokenRe = RegExp(
        r'"(?:[^"\\]|\\.)*"|<[^>]+>|-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b|\b(?:true|false|null)\b');

    final spans = <InlineSpan>[];
    var pos = 0;
    for (final m in tokenRe.allMatches(pretty)) {
      if (m.start > pos) {
        spans.add(TextSpan(text: pretty.substring(pos, m.start),
            style: base.copyWith(color: AppColors.jsonPunct)));
      }
      final t = m.group(0)!;
      Color color;
      if (t.startsWith('"')) {
        // 看后面第一个非空白字符是否为冒号 → 键
        final rest = pretty.substring(m.end);
        final next = rest.trimLeft();
        color = next.startsWith(':') ? AppColors.jsonKey : AppColors.jsonStr;
      } else if (t.startsWith('<')) {
        color = AppColors.jsonKey;
      } else if (t == 'true' || t == 'false' || t == 'null') {
        color = AppColors.put;
      } else {
        color = AppColors.jsonNum;
      }
      spans.add(TextSpan(text: t, style: base.copyWith(color: color)));
      pos = m.end;
    }
    if (pos < pretty.length) {
      spans.add(TextSpan(
          text: pretty.substring(pos),
          style: base.copyWith(color: AppColors.jsonPunct)));
    }
    return TextSpan(children: spans);
  }
}
