import 'package:flutter/material.dart';

import '../modules/toolbox_module.dart';

/// 二期模块的纯元数据占位：无实现，仅用于侧栏 / 首页 / 搜索 / 模块管理展示。
/// 点击时由壳统一提示「将在二期提供」（SPEC §4.5）。
class PlannedModule extends ToolboxModule {
  const PlannedModule({
    required this.id,
    required this.name,
    required this.category,
    required this.summary,
    required this.icon,
    this.keywords = const <String>[],
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String category;
  @override
  final String summary;
  @override
  final List<String> keywords;
  @override
  final IconData icon;

  @override
  String get version => '二期';
  @override
  bool get enabled => false;
  @override
  Widget buildPage(BuildContext context, {Object? intent}) => const SizedBox.shrink();
}

/// 模块注册表：侧栏、首页「全部工具」、全局搜索、模块管理的唯一数据源。
class ModuleRegistry {
  ModuleRegistry(this._modules)
      : assert(
          _modules.length == _modules.map((m) => m.id).toSet().length,
          '模块 id 必须唯一',
        );

  final List<ToolboxModule> _modules;

  List<ToolboxModule> get all => List.unmodifiable(_modules);

  List<ToolboxModule> get enabledModules =>
      List.unmodifiable(_modules.where((m) => m.enabled));

  ToolboxModule? byId(String id) {
    for (final m in _modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// 按注册顺序分组的 (分类, 模块列表) 视图。
  List<(String, List<ToolboxModule>)> get groupedByCategory {
    final entries = <(String, List<ToolboxModule>)>[];
    for (final m in _modules) {
      final idx = entries.indexWhere((e) => e.$1 == m.category);
      if (idx == -1) {
        entries.add((m.category, <ToolboxModule>[m]));
      } else {
        entries[idx].$2.add(m);
      }
    }
    return entries;
  }
}

/// 二期模块清单（元数据，无实现；SPEC §5.3）。
const plannedModules = <PlannedModule>[



  PlannedModule(
      id: 'base64',
      name: 'Base64 编解码',
      category: '编码转换',
      summary: '文本与 Base64 互转',
      icon: Icons.terminal,
      keywords: ['base64', '编码', '解码']),
  PlannedModule(
      id: 'timestamp',
      name: '时间戳转换',
      category: '编码转换',
      summary: 'Unix 时间戳与日期互转',
      icon: Icons.schedule,
      keywords: ['时间戳', 'unix', 'date', '日期']),
  PlannedModule(
      id: 'regex_test',
      name: '正则测试',
      category: '开发辅助',
      summary: '正则表达式验证与提取',
      icon: Icons.rule,
      keywords: ['正则', 'regex', '表达式']),
  PlannedModule(
      id: 'hash',
      name: '哈希计算',
      category: '开发辅助',
      summary: 'MD5 / SHA 系列摘要',
      icon: Icons.fingerprint,
      keywords: ['md5', 'sha', '哈希', '摘要']),
  PlannedModule(
      id: 'uuid',
      name: 'UUID 生成',
      category: '开发辅助',
      summary: '批量生成唯一标识',
      icon: Icons.vpn_key_outlined,
      keywords: ['uuid', 'guid', '唯一']),
];



