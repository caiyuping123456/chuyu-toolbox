import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/module_registry.dart';
import '../core/theme.dart';
import '../modules/toolbox_module.dart';
import 'widgets.dart';

/// 模块管理页（SPEC §4.4）：清单 + 启停开关 + 导入/市场二期占位。
class ModuleManagerPage extends StatelessWidget {
  const ModuleManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = context.watch<ModuleRegistry>();

    void todo(String text) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(text), duration: const Duration(seconds: 2)));
    }

    return ListView(
      padding: const EdgeInsets.all(26),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('模块管理', style: AppTypography.title),
                SizedBox(height: 4),
                Text('启用 / 停用模块；模块以独立目录形式扩展，新增模块无需修改核心。',
                    style: AppTypography.body),
              ],
            ),
            const Spacer(),
            _GhostChip(
                icon: Icons.extension_outlined,
                label: '导入本地模块 · 二期',
                onTap: () => todo('导入本地模块将在二期提供')),
            const SizedBox(width: 8),
            _GhostChip(
                icon: Icons.storefront_outlined,
                label: '模块市场 · 二期',
                onTap: () => todo('模块市场将在二期提供')),
          ],
        ),
        const SizedBox(height: 14),
        for (final ToolboxModule m in registry.all) ...[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: m.enabled ? AppColors.accentSoft : AppColors.fill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(m.icon,
                      size: 16,
                      color: m.enabled ? AppColors.accent : AppColors.text4),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(m.name,
                              style: AppTypography.nav.copyWith(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          MiniChip(m.category),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(m.summary, style: AppTypography.aux),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(m.version, style: AppTypography.aux),
                Switch(
                  value: m.enabled,
                  onChanged: m.enabled
                      ? (_) => todo('模块启停将在后续版本提供')
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        const Text(
          '模块 = 一个独立目录（Dart 实现本模块接口 + 注册表登记一行）；侧栏 / 首页 / 搜索 / 本页均由注册表自动生成。',
          style: AppTypography.aux,
        ),
      ],
    );
  }
}

class _GhostChip extends StatelessWidget {
  const _GhostChip(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      hoverColor: AppColors.hover,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.text3),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.nav.copyWith(
                    fontSize: 12, color: AppColors.text3)),
          ],
        ),
      ),
    );
  }
}
