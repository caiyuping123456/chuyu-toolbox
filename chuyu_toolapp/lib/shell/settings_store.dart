import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 全局设置（M5 增强）：持久化到 `%APPDATA%\chuyu-toolbox\settings.json`。
class SettingsStore extends ChangeNotifier {
  SettingsStore({Directory? baseDir}) : _baseDirOverride = baseDir;

  final Directory? _baseDirOverride;
  Directory? _dir;
  bool _loaded = false;
  bool _dark = false;
  int _defaultTimeoutMs = 30000;
  bool _followRedirects = true;
  int _historyLimit = 200;

  bool get loaded => _loaded;
  bool get dark => _dark;
  int get defaultTimeoutMs => _defaultTimeoutMs;
  bool get followRedirects => _followRedirects;
  int get historyLimit => _historyLimit;

  Future<void> load() async {
    if (_baseDirOverride != null) {
      _dir = _baseDirOverride;
    } else {
      try {
        final sup = await getApplicationSupportDirectory();
        final appData = sup.parent.parent;
        _dir = Directory(
            '${appData.path}${Platform.pathSeparator}chuyu-toolbox');
      } catch (_) {
        _dir = Directory(
            '${Directory.systemTemp.path}${Platform.pathSeparator}chuyu-toolbox-settings');
      }
    }
    final f = File('${_dir!.path}${Platform.pathSeparator}settings.json');
    try {
      if (f.existsSync()) {
        final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        _dark = json['dark'] as bool? ?? false;
        _defaultTimeoutMs = json['defaultTimeoutMs'] as int? ?? 30000;
        _followRedirects = json['followRedirects'] as bool? ?? true;
        _historyLimit = json['historyLimit'] as int? ?? 200;
      }
    } catch (_) {
      // 损坏 → 默认值
    }
    _loaded = true;
    notifyListeners();
  }

  void setDark(bool v) {
    _dark = v;
    _persist();
    notifyListeners();
  }

  void setDefaultTimeout(int seconds) {
    _defaultTimeoutMs = (seconds <= 0 ? 30 : seconds) * 1000;
    _persist();
    notifyListeners();
  }

  void setFollowRedirects(bool v) {
    _followRedirects = v;
    _persist();
    notifyListeners();
  }

  void setHistoryLimit(int v) {
    _historyLimit = v.clamp(10, 1000);
    _persist();
    notifyListeners();
  }

  void _persist() {
    if (_dir == null) return;
    try {
      _dir!.createSync(recursive: true);
      File('${_dir!.path}${Platform.pathSeparator}settings.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert({
        'dark': _dark,
        'defaultTimeoutMs': _defaultTimeoutMs,
        'followRedirects': _followRedirects,
        'historyLimit': _historyLimit,
      }));
    } catch (e) {
      debugPrint('SettingsStore 写入失败: $e');
    }
  }
}
