import 'dart:io';

/// 导出结果。
class ExportResult {
  const ExportResult._({this.path, this.error});
  factory ExportResult.ok(String path) => ExportResult._(path: path);
  factory ExportResult.fail(String msg) => ExportResult._(error: msg);

  final String? path;
  final String? error;
  bool get ok => error == null;
}

/// 统一导出：写到 `下载\chuyu-toolbox\`，文件名带时间戳，冲突自动加序号。
abstract final class ExportService {
  static Directory? baseDirOverride; // 测试注入

  static Future<Directory> _dir() async {
    if (baseDirOverride != null) return baseDirOverride!;
    final home = Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    final dl = Directory('$home${Platform.pathSeparator}Downloads'
        '${Platform.pathSeparator}chuyu-toolbox');
    await dl.create(recursive: true);
    return dl;
  }

  static String _stamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  /// [ext] 不含点，如 'json' / 'txt' / 'csv'。
  static Future<ExportResult> exportText(String content, String baseName, String ext,
      {DateTime? now}) async {
    final text = content;
    if (text.isEmpty) return ExportResult.fail('内容为空，无需导出');
    try {
      final dir = await _dir();
      final t = now ?? DateTime.now();
      var name = '${baseName}_${_stamp(t)}.$ext';
      var f = File('${dir.path}${Platform.pathSeparator}$name');
      var n = 1;
      while (f.existsSync()) {
        name = '${baseName}_${_stamp(t)}-$n.$ext';
        f = File('${dir.path}${Platform.pathSeparator}$name');
        n++;
      }
      await f.writeAsString(text, flush: true);
      return ExportResult.ok(f.path);
    } catch (e) {
      return ExportResult.fail('导出失败：$e');
    }
  }
}
