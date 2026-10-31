import 'package:flutter/foundation.dart';

/// 壳页面路由（单窗口 + 页面切换，SPEC §4.1）。
enum ShellPage { home, module, manager, settings }

/// 全局 UI 状态：当前页面、模块深链接意图、全局搜索面板开关。
class AppState extends ChangeNotifier {
  ShellPage _page = ShellPage.home;
  final List<String> _recent = <String>[];
  String? _activeModuleId;
  Object? _moduleIntent;
  bool _searchOpen = false;

  ShellPage get page => _page;
  String? get activeModuleId => _activeModuleId;
  Object? get moduleIntent => _moduleIntent;
  bool get searchOpen => _searchOpen;

  void goHome() {
    _page = ShellPage.home;
    _activeModuleId = null;
    _moduleIntent = null;
    notifyListeners();
  }

  void goManager() {
    _page = ShellPage.manager;
    _activeModuleId = null;
    _moduleIntent = null;
    notifyListeners();
  }

  void goSettings() {
    _page = ShellPage.settings;
    _activeModuleId = null;
    _moduleIntent = null;
    notifyListeners();
  }

  /// 进入模块页；intent 为模块深链接状态（如 HTTP 的聚焦 URL / 指定页签）。
  List<String> get recentModules => List<String>.unmodifiable(_recent);

  void openModule(String id, {Object? intent}) {
    _page = ShellPage.module;
    _activeModuleId = id;
    _recent
      ..remove(id)
      ..insert(0, id);
    if (_recent.length > 4) _recent.removeLast();
    _moduleIntent = intent;
    _searchOpen = false;
    notifyListeners();
  }

  void openSearch() {
    if (!_searchOpen) {
      _searchOpen = true;
      notifyListeners();
    }
  }

  void closeSearch() {
    if (_searchOpen) {
      _searchOpen = false;
      notifyListeners();
    }
  }
}

