import 'dart:convert';

import 'package:yaml/yaml.dart';

enum Fmt { json, yaml, csv, xml }

extension FmtX on Fmt {
  String get label => switch (this) {
        Fmt.json => 'JSON',
        Fmt.yaml => 'YAML',
        Fmt.csv => 'CSV',
        Fmt.xml => 'XML',
      };
}

class ConvertResult {
  const ConvertResult._({this.output, this.error});
  factory ConvertResult.ok(String out) => ConvertResult._(output: out);
  factory ConvertResult.fail(String msg) => ConvertResult._(error: msg);
  final String? output;
  final String? error;
  bool get ok => error == null;
}

abstract final class FormatConverter {
  static const int maxBytes = 2 * 1024 * 1024;

  static Object? _parseJson(String s) => jsonDecode(s);

  static Object? _parseYaml(String s) {
    final y = loadYaml(s);
    return _yamlToNative(y);
  }

  static Object? _yamlToNative(dynamic y) {
    if (y is YamlMap) {
      return y.map((k, v) => MapEntry('$k', _yamlToNative(v)));
    }
    if (y is YamlList) return y.map(_yamlToNative).toList();
    return y;
  }

  static List<Map<String, String>> _parseCsv(String s) {
    final rows = <List<String>>[];
    final cell = StringBuffer();
    var inQuote = false;
    var row = <String>[];
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (inQuote) {
        if (ch == '"') {
          if (i + 1 < s.length && s[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            inQuote = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"') {
        inQuote = true;
      } else if (ch == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < s.length && s[i + 1] == '\n') i++;
        row.add(cell.toString());
        cell.clear();
        if (row.any((c) => c.isNotEmpty) || rows.isNotEmpty) rows.add(row);
        row = <String>[];
      } else {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    if (rows.isEmpty) return <Map<String, String>>[];
    final header = rows.first;
    return [
      for (final r in rows.skip(1))
        {for (var i = 0; i < header.length; i++) header[i]: i < r.length ? r[i] : ''}
    ];
  }

  static Object? _parseXml(String s) {
    final m = RegExp(r'^\s*<([\w:-]+)>([\s\S]*?)</\1>\s*$').firstMatch(s);
    if (m == null) return _unesc(s.trim());
    final tag = m.group(1)!;
    final inner = m.group(2)!.trim();
    final nested = RegExp(r'<([\w:-]+)>([\s\S]*?)</\1>');
    if (!nested.hasMatch(inner)) return {tag: _unesc(inner)};
    final map = <String, Object?>{};
    final groups = <String, List<String>>{};
    for (final n in nested.allMatches(inner)) {
      groups.putIfAbsent(n.group(1)!, () => []).add(n.group(2)!);
    }
    for (final e in groups.entries) {
      if (e.value.length > 1) {
        map[e.key] = [
          for (final v in e.value)
            nested.hasMatch(v.trim()) ? _parseXml(v.trim()) : _unesc(v.trim())
        ];
      } else {
        final v = e.value.first.trim();
        map[e.key] = nested.hasMatch(v) ? _parseXml(v) : _unesc(v);
      }
    }
    return {tag: map};
  }

  static String _unesc(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  static String _toJson(Object? v) =>
      const JsonEncoder.withIndent('  ').convert(v);

  static String _toYaml(Object? v, {int depth = 0}) {
    const pad = '  ';
    if (v is Map) {
      if (v.isEmpty) return '{}';
      return v.entries.map((e) {
        final val = e.value;
        if (val is Map && val.isNotEmpty) {
          return '${pad * depth}${e.key}:\n${_toYaml(val, depth: depth + 1)}';
        }
        if (val is List && val.isNotEmpty) {
          return '${pad * depth}${e.key}:\n${_toYaml(val, depth: depth + 1)}';
        }
        return '${pad * depth}${e.key}: ${_scalar(val)}';
      }).join('\n');
    }
    if (v is List) {
      if (v.isEmpty) return '[]';
      return v.map((item) {
        if (item is Map && item.isNotEmpty) {
          final inner = _toYaml(item, depth: depth + 1);
          return '${pad * depth}- ${inner.trimLeft()}';
        }
        return '${pad * depth}- ${_scalar(item)}';
      }).join('\n');
    }
    return '${pad * depth}${_scalar(v)}';
  }

  static String _scalar(Object? v) {
    if (v == null) return 'null';
    if (v is num || v is bool) return '$v';
    final s = '$v';
    final needsQuote = s.isEmpty ||
        s.contains(':') ||
        s.contains('#') ||
        s.startsWith(' ') ||
        s.endsWith(' ') ||
        s.contains('\n') ||
        double.tryParse(s) != null ||
        ['true', 'false', 'null', 'yes', 'no', '~'].contains(s.toLowerCase());
    return needsQuote ? '"${s.replaceAll('"', '""')}"' : s;
  }

  static String _csvEscape(String v) =>
      v.contains(',') || v.contains('"') || v.contains('\n')
          ? '"${v.replaceAll('"', '""')}"'
          : v;

  static ConvertResult _toCsv(Object? v) {
    if (v is! List || v.isEmpty || v.first is! Map) {
      return ConvertResult.fail('CSV 仅支持「对象数组」，且至少一行');
    }
    final cols = <String>{};
    for (final row in v) {
      cols.addAll((row as Map).keys.map((k) => '$k'));
    }
    final buf = StringBuffer();
    buf.writeln(cols.map(_csvEscape).join(','));
    for (final row in v.cast<Map>()) {
      buf.writeln(cols.map((c) => _csvEscape('${row[c] ?? ''}')).join(','));
    }
    return ConvertResult.ok(buf.toString().trimRight());
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _toXmlTag(String tag, Object? val, int depth) {
    final pad = '  ' * depth;
    if (val is Map) {
      if (val.isEmpty) return '$pad<$tag />';
      final inner = val.entries
          .map((e) => _toXmlTag(e.key, e.value, depth + 1))
          .join('\n');
      return '$pad<$tag>\n$inner\n$pad</$tag>';
    }
    if (val is List) {
      final inner =
          val.map((i) => _toXmlTag('item', i, depth + 1)).join('\n');
      return '$pad<$tag>\n$inner\n$pad</$tag>';
    }
    return '$pad<$tag>${_esc('$val')}</$tag>';
  }

  static String _toXml(Object? v) => _toXmlTag('root', v, 0);

  static Object? _sortKeys(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => '$k').toList()..sort();
      return {for (final k in keys) k: _sortKeys(v[k])};
    }
    if (v is List) return v.map(_sortKeys).toList();
    return v;
  }

  static String _brief(Object e) {
    final s = '$e';
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }

  static ConvertResult convert(String input, Fmt from, Fmt to,
      {bool sortKeys = false}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return ConvertResult.fail('请输入内容');
    if (utf8.encode(trimmed).length > maxBytes) {
      return ConvertResult.fail('内容超过 2 MB 上限');
    }

    Object? model;
    try {
      model = switch (from) {
        Fmt.json => _parseJson(trimmed),
        Fmt.yaml => _parseYaml(trimmed),
        Fmt.csv => _parseCsv(trimmed),
        Fmt.xml => _parseXml(trimmed),
      };
    } catch (e) {
      return ConvertResult.fail('${from.label} 解析失败：${_brief(e)}');
    }

    if (model == null) return ConvertResult.fail('内容为空');

    if (sortKeys && model is Map) {
      model = _sortKeys(model);
    } else if (sortKeys && model is List) {
      model = [for (final i in model) i is Map ? _sortKeys(i) : i];
    }

    try {
      if (to == Fmt.csv) {
        final r = _toCsv(model);
        if (!r.ok) return ConvertResult.fail(r.error!);
        return ConvertResult.ok(r.output!);
      }
      final out = switch (to) {
        Fmt.json => _toJson(model),
        Fmt.yaml => _toYaml(model),
        Fmt.xml => _toXml(model),
        Fmt.csv => throw StateError('unreachable'),
      };
      return ConvertResult.ok(out);
    } catch (e) {
      return ConvertResult.fail('${to.label} 输出失败：${_brief(e)}');
    }
  }
}

