import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/module_registry.dart';
import '../core/theme.dart';
import 'app_state.dart';
import 'widgets.dart';

/// 左侧导航：品牌 → 搜索入口 → 首页 → 分类模块清单 → 模块管理/设置。
/// 数据全部来自模块注册表（SPEC §4.1）；窗口 < 780px 时收成 56px 图标列。
class NavSidebar extends StatelessWidget {
  const NavSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final registry = context.watch<ModuleRegistry>();
    final narrow = MediaQuery.sizeOf(context).width < 780;
    final width = narrow ? 56.0 : 216.0;

    void hint(String name) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('「$name」将在二期提供'),
          duration: const Duration(seconds: 2),
        ));
    }

    final items = <Widget>[
      NavItem(
        icon: Icons.search,
        label: '搜索工具',
        iconOnly: narrow,
        onTap: state.openSearch,
        trailing: narrow ? null : const MiniChip('Ctrl K'),
      ),
      NavItem(
        icon: Icons.home_outlined,
        label: '首页',
        iconOnly: narrow,
        selected: state.page == ShellPage.home,
        onTap: state.goHome,
      ),
      for (final group in registry.groupedByCategory) ...[
        if (!narrow)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
            child: Text(
              group.$1,
              style: AppTypography.aux.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text4),
            ),
          ),
        for (final m in group.$2)
          NavItem(
            icon: m.icon,
            label: m.name,
            iconOnly: narrow,
            selected:
                state.page == ShellPage.module && state.activeModuleId == m.id,
            onTap: m.enabled ? () => state.openModule(m.id) : () => hint(m.name),
            trailing: m.enabled ? null : (narrow ? null : const MiniChip('二期')),
          ),
      ],
    ];

    return Container(
      width: width,
      color: AppColors.side,
      child: Column(
        children: [
          if (narrow) const _BrandCompact() else const _Brand(),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding:
                  EdgeInsets.symmetric(vertical: 8, horizontal: narrow ? 4 : 6),
              children: items,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                NavItem(
                  icon: Icons.grid_view_outlined,
                  label: '模块管理',
                  iconOnly: narrow,
                  selected: state.page == ShellPage.manager,
                  onTap: state.goManager,
                ),
                NavItem(
                  icon: Icons.settings_outlined,
                  label: '设置',
                  iconOnly: narrow,
                  selected: state.page == ShellPage.settings,
                  onTap: state.goSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('CY',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ChuYu 万能工具箱',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              Text('轻量 · 模块化 · 本地',
                  style: TextStyle(fontSize: 9.5, color: AppColors.text3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandCompact extends StatelessWidget {
  const _BrandCompact();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('CY',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}
