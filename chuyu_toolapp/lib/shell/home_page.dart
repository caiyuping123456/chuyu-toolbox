import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/module_registry.dart';
import '../core/theme.dart';
import '../modules/toolbox_module.dart';
import 'app_state.dart';
import 'quick_actions.dart';
import 'widgets.dart';

/// 首页：介绍 + 全局搜索入口 + 快速入口 + 全部工具（SPEC §4.2）。
/// 纯介绍与跳转，不放请求表单等具体功能区；默认 960×640 一屏放下。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final registry = context.watch<ModuleRegistry>();
    final total = registry.all.length;
    final enabledCount = registry.enabledModules.length;

    void hint(String name) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('「$name」将在二期提供'),
          duration: const Duration(seconds: 2),
        ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 介绍区 ──
          const Text('ChuYu 万能工具箱', style: AppTypography.h1),
          const SizedBox(height: 6),
          const Text(
            '把常用开发小工具装进一个本地 App：HTTP 请求、WebSocket、端口检测与 JSON 格式化已内置——'
            '发请求、调长连接、查端口、理 JSON 都在这里完成；后续模块持续扩展，装一个 App 顶一抽屉工具。',
            style: AppTypography.body,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              MiniChip('$total 个工具规划'),
              MiniChip('$enabledCount 个已启用'),
              const MiniChip('数据仅存本机'),
            ],
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // ── 全局搜索入口 ──
          Material(
            color: AppColors.panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              onTap: state.openSearch,
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: AppColors.text3),
                    const SizedBox(width: 10),
                    const Text('搜索工具、操作…',
                        style: TextStyle(fontSize: 12.5, color: AppColors.text3)),
                    const Spacer(),
                    const MiniChip('Ctrl K'),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // ── 最近使用（M5 增强：高频访问）──
          if (state.recentModules.isNotEmpty) ...[
            SectionLabel('最近使用'),
            Row(
              children: [
                for (final id in state.recentModules)
                  if (registry.byId(id) != null)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: id == state.recentModules.first ? 0 : 10),
                        child: _QuickCard(
                          action: QuickAction(
                            icon: registry.byId(id)!.icon,
                            title: registry.byId(id)!.name,
                            subtitle: registry.byId(id)!.summary,
                            run: (s) => s.openModule(id),
                          ),
                          onTap: () => state.openModule(id),
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],

          // ── 快速入口（4 个固定深链接，SPEC §4.2）──
          Row(
            children: [
              for (var i = 0; i < quickActions.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                    child: _QuickCard(
                      action: quickActions[i],
                      onTap: () => quickActions[i].run(state),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // ── 全部工具（按分类三列，仅展示与跳转）──
          SectionLabel('全部工具（$total）'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < registry.groupedByCategory.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registry.groupedByCategory[i].$1,
                          style: AppTypography.aux.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text3),
                        ),
                        const SizedBox(height: 6),
                        for (final m in registry.groupedByCategory[i].$2)
                          _ToolRow(
                            module: m,
                            onTap: m.enabled
                                ? () => state.openModule(m.id)
                                : () => hint(m.name),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.action, required this.onTap});

  final QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(action.icon, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.nav.copyWith(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(action.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.aux),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.module, required this.onTap});

  final ToolboxModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = module.enabled;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      hoverColor: AppColors.hover,
      child: SizedBox(
        height: 30,
        child: Row(
          children: [
            Icon(module.icon,
                size: 15, color: enabled ? AppColors.text3 : AppColors.text4),
            const SizedBox(width: 8),
            Text(module.name,
                style: AppTypography.nav.copyWith(
                    color: enabled ? AppColors.text : AppColors.text3)),
            const Spacer(),
            if (enabled)
              const MiniChip('可用',
                  color: AppColors.accent, background: AppColors.accentSoft)
            else
              const MiniChip('二期'),
          ],
        ),
      ),
    );
  }
}




