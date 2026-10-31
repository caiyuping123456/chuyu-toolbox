import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// HTTP 模块存储：集合 / 历史 JSON 落盘（SPEC §8）。
/// - 位置：`%APPDATA%\chuyu-toolbox\modules\http_test\{collections,history}.json`
/// - 历史上限 200 条，新的在最前
/// - 文件损坏按空数据处理，不崩溃
/// - 测试可注入 [baseDir] 用临时目录
class HttpStore extends ChangeNotifier {
  HttpStore({Directory? baseDir}) : _baseDirOverride = baseDir ?? debugBaseDir;

  /// 测试注入：widget 测试没有 path_provider 时使用固定目录（生产不设置）。
  @visibleForTesting
  static Directory? debugBaseDir;

  static const int historyLimit = 200;

  final Directory? _baseDirOverride;
  Directory? _base;

  List<RequestCollection> collections = <RequestCollection>[];
  List<HistoryEntry> history = <HistoryEntry>[];

  bool get loaded => _base != null;

  Future<void> load() async {
    if (_baseDirOverride != null) {
      _base = _baseDirOverride;
    } else {
      try {
        _base = await defaultHttpDataDir();
      } catch (_) {
        // 测试环境（无 path_provider 通道）退回临时目录，不崩溃
        final fb = Directory(
            '${Directory.systemTemp.path}${Platform.pathSeparator}chuyu-toolbox-fallback');
        fb.createSync(recursive: true);
        _base = fb;
      }
    }
    collections = _readList('collections.json', RequestCollection.fromJson);
    history = _readList('history.json', HistoryEntry.fromJson);
    notifyListeners();
  }

  // ── 集合 ────────────────────────────────────────────────

  RequestCollection createCollection(String name) {
    final c = RequestCollection(name: name.trim().isEmpty ? '未命名集合' : name.trim());
    collections.add(c);
    _persistCollections();
    notifyListeners();
    return c;
  }

  void renameCollection(String id, String name) {
    final c = _byId(id);
    if (c == null) return;
    c.name = name.trim().isEmpty ? c.name : name.trim();
    _persistCollections();
    notifyListeners();
  }

  void deleteCollection(String id) {
    collections.removeWhere((c) => c.id == id);
    _persistCollections();
    notifyListeners();
  }

  /// 保存（或更新）请求到集合；req.id 为空时生成新 id。
  void saveRequest(String collectionId, SavedRequest req) {
    final c = _byId(collectionId);
    if (c == null) return;
    final idx = c.items.indexWhere((r) => r.id == req.id);
    if (idx == -1) {
      c.items.add(req);
    } else {
      c.items[idx] = req;
    }
    _persistCollections();
    notifyListeners();
  }

  void deleteRequest(String collectionId, String requestId) {
    final c = _byId(collectionId);
    if (c == null) return;
    c.items.removeWhere((r) => r.id == requestId);
    _persistCollections();
    notifyListeners();
  }

  // ── 历史 ────────────────────────────────────────────────

  void addHistory(HistoryEntry entry) {
    history.insert(0, entry);
    if (history.length > historyLimit) {
      history.removeRange(historyLimit, history.length);
    }
    _persistHistory();
    notifyListeners();
  }

  void clearHistory() {
    history.clear();
    _persistHistory();
    notifyListeners();
  }

  // ── 内部 ────────────────────────────────────────────────

  RequestCollection? _byId(String id) {
    for (final c in collections) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<T> _readList<T>(String file, T Function(Map<String, dynamic>) fromJson) {
    try {
      final f = File('${_base!.path}${Platform.pathSeparator}$file');
      if (!f.existsSync()) return <T>[];
      final raw = f.readAsStringSync();
      if (raw.trim().isEmpty) return <T>[];
      final list = jsonDecode(raw) as List<dynamic>;
      return <T>[
        for (final e in list) fromJson(e as Map<String, dynamic>)
      ];
    } catch (_) {
      return <T>[]; // 文件损坏 → 按空处理
    }
  }

  void _persistCollections() =>
      _write('collections.json', [for (final c in collections) c.toJson()]);

  void _persistHistory() =>
      _write('history.json', [for (final h in history) h.toJson()]);

  void _write(String file, List<Map<String, dynamic>> data) {
    if (_base == null) return;
    try {
      _base!.createSync(recursive: true);
      final f = File('${_base!.path}${Platform.pathSeparator}$file');
      f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      debugPrint('HttpStore 写入失败: $e');
    }
  }
}

/// 默认数据目录：`%APPDATA%\chuyu-toolbox\modules\http_test\`。
Future<Directory> defaultHttpDataDir() async {
  final sup = await getApplicationSupportDirectory();
  // Windows: getApplicationSupportDirectory = %APPDATA%\<org>\<app>
  final appData = sup.parent.parent;
  final dir = Directory(
      '${appData.path}${Platform.pathSeparator}chuyu-toolbox${Platform.pathSeparator}modules${Platform.pathSeparator}http_test');
  await dir.create(recursive: true);
  return dir;
}

