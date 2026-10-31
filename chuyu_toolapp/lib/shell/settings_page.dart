import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'widgets.dart';

/// 设置页（M1 简版，更多选项随版本提供）。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(26),
      children: [
        const Text('设置', style: AppTypography.title),
        const SizedBox(height: 4),
        const Text('全局设置；更多选项随版本提供。', style: AppTypography.body),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(
            children: [
              _row('版本', 'v0.1.0（M1 壳骨架）'),
              const Divider(height: 1, color: AppColors.borderSoft),
              _row('界面语言', '简体中文'),
              const Divider(height: 1, color: AppColors.borderSoft),
              _row('主题', '浅色 · 白色简约（深色为二期）'),
              const Divider(height: 1, color: AppColors.borderSoft),
              _row('HTTP 默认超时', '30 秒（M2 可修改）'),
              const Divider(height: 1, color: AppColors.borderSoft),
              _row('数据目录', r'%APPDATA%\chuyu-toolbox（M3 启用）'),
              const Divider(height: 1, color: AppColors.borderSoft),
              _row('检查更新', '二期'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label,
              style: AppTypography.nav.copyWith(color: AppColors.text2)),
          const Spacer(),
          Text(value, style: AppTypography.aux.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
