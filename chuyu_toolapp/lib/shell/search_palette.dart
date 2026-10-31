import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/module_registry.dart';
import '../core/theme.dart';
import 'app_state.dart';
import 'quick_actions.dart';
import 'widgets.dart';

class _PaletteItem {
  const _PaletteItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.group,
    this.planned = false,
    required this.run,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String group;
  final bool planned;
  final void Function() run;
}

/// 全局搜索命令面板（SPEC §4.5）：Ctrl K / / 打开，↑↓ 选择，Enter 执行，Esc 关闭。
/// 数据源 = 模块注册表 + 快捷入口；纯内存过滤，不联网。
class SearchPalette extends StatefulWidget {
  const SearchPalette({super.key});

  @override
  State<SearchPalette> createState() => _SearchPaletteState();
}

class _SearchPaletteState extends State<SearchPalette> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<_PaletteItem> _items = const <_PaletteItem>[];
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _rebuild('');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild(String query) {
    final state = context.read<AppState>();
    final registry = context.read<ModuleRegistry>();
    final q = query.trim().toLowerCase();
    bool match(List<String> fields) =>
        q.isEmpty || fields.any((f) => f.toLowerCase().contains(q));

    final items = <_PaletteItem>[
      for (final qa in quickActions)
        if (match(<String>[qa.title, qa.subtitle, '快捷', 'quick']))
          _PaletteItem(
            icon: qa.icon,
            title: qa.title,
            subtitle: qa.subtitle,
            group: '快捷入口',
            run: () {
              state.closeSearch();
              qa.run(state);
            },
          ),
      for (final m in registry.enabledModules)
        if (match(<String>[m.name, m.category, m.summary, ...m.keywords]))
          _PaletteItem(
            icon: m.icon,
            title: m.name,
            subtitle: '${m.category} · ${m.summary}',
            group: '可用模块',
            run: () {
              state.closeSearch();
              state.openModule(m.id);
            },
          ),
      for (final m in registry.all.where((m) => !m.enabled))
        if (match(<String>[m.name, m.category, m.summary, ...m.keywords]))
          _PaletteItem(
            icon: m.icon,
            title: m.name,
            subtitle: m.summary,
            group: '二期模块',
            planned: true,
            run: () {
              state.closeSearch();
              _hint(m.name);
            },
          ),
    ];

    setState(() {
      _items = items;
      if (_selected >= items.length) _selected = 0;
    });
  }

  void _hint(String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('「$name」将在二期提供'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _move(int delta) {
    if (_items.isEmpty) return;
    setState(() {
      _selected = (_selected + delta + _items.length) % _items.length;
    });
  }

  void _runSelected() {
    if (_selected < _items.length) _items[_selected].run();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // 在焦点冒泡阶段先于输入框拦截 ↑↓/Enter/Esc（SPEC §4.5 键盘规则）。
    final panel = Focus(
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowUp) {
          _move(-1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _move(1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.escape) {
          state.closeSearch();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.enter) {
          _runSelected();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.window),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: AppColors.text3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('palette_input'),
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.text),
                        cursorColor: AppColors.accent,
                        decoration: const InputDecoration(
                          hintText: '搜索工具或操作…',
                          border: InputBorder.none,
                          isDense: true,
                          hintStyle:
                              TextStyle(fontSize: 12.5, color: AppColors.text3),
                        ),
                        onChanged: _rebuild,
                        onSubmitted: (_) => _runSelected(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const MiniChip('Esc'),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: _items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child:
                            Text('没有匹配的结果', style: AppTypography.body),
                      )
                    : Material(
                        color: Colors.transparent,
                        child: ListView(
                          key: const ValueKey('palette_list'),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          children: _buildRows(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            color: AppColors.scrim,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: state.closeSearch,
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  top: 88,
                  left: 0,
                  right: 0,
                  child: Center(child: panel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];
    String? lastGroup;
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      if (it.group != lastGroup) {
        lastGroup = it.group;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Text(
            it.group,
            style: const TextStyle(
                fontSize: 9.5,
                letterSpacing: 0.6,
                color: AppColors.text4),
          ),
        ));
      }
      final selected = i == _selected;
      rows.add(InkWell(
        onTap: it.run,
        onHover: (h) {
          if (h && _selected != i) setState(() => _selected = i);
        },
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: selected ? AppColors.accentSoft : null,
          child: Row(
            children: [
              Icon(
                it.icon,
                size: 15,
                color: it.planned
                    ? AppColors.text4
                    : (selected ? AppColors.accent : AppColors.text3),
              ),
              const SizedBox(width: 10),
              Text(
                it.title,
                style: AppTypography.nav.copyWith(
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  it.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.aux,
                ),
              ),
              if (it.planned) const MiniChip('二期'),
            ],
          ),
        ),
      ));
    }
    return rows;
  }
}
