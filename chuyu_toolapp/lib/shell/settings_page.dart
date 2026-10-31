import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import 'settings_store.dart';
import 'widgets.dart';

/// 设置页（M5 增强）：主题 / 默认超时 / 重定向 / 历史上限，即时持久化。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    return ListView(
      padding: const EdgeInsets.all(26),
      children: [
        const Text('设置', style: AppTypography.title),
        const SizedBox(height: 4),
        const Text('全局设置，保存到 %APPDATA%\\chuyu-toolbox\\settings.json',
            style: AppTypography.body),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(
            children: [
              SwitchListTile(
                key: const ValueKey('setting_dark'),
                title: const Text('深色主题',
                    style: TextStyle(fontSize: 12.5, color: AppColors.text)),
                subtitle: Text('即时生效，下次启动保持',
                    style: AppTypography.aux),
                value: s.dark,
                onChanged: (v) => context.read<SettingsStore>().setDark(v),
              ),
              const Divider(height: 1, color: AppColors.borderSoft),
              ListTile(
                dense: true,
                title: const Text('HTTP 默认超时',
                    style: TextStyle(fontSize: 12.5, color: AppColors.text)),
                subtitle: Text('当前 ${s.defaultTimeoutMs ~/ 1000} 秒',
                    style: AppTypography.aux),
                trailing: DropdownButton<int>(
                  key: const ValueKey('setting_timeout'),
                  value: s.defaultTimeoutMs,
                  items: const [
                    DropdownMenuItem(value: 10000, child: Text('10 秒')),
                    DropdownMenuItem(value: 30000, child: Text('30 秒')),
                    DropdownMenuItem(value: 60000, child: Text('60 秒')),
                    DropdownMenuItem(value: 120000, child: Text('120 秒')),
                  ],
                  onChanged: (v) => context
                      .read<SettingsStore>()
                      .setDefaultTimeout((v ?? 30000) ~/ 1000),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSoft),
              SwitchListTile(
                key: const ValueKey('setting_redirect'),
                title: const Text('HTTP 默认跟随重定向',
                    style: TextStyle(fontSize: 12.5, color: AppColors.text)),
                value: s.followRedirects,
                onChanged: (v) =>
                    context.read<SettingsStore>().setFollowRedirects(v),
              ),
              const Divider(height: 1, color: AppColors.borderSoft),
              ListTile(
                dense: true,
                title: const Text('历史上限',
                    style: TextStyle(fontSize: 12.5, color: AppColors.text)),
                subtitle: Text('当前 ${s.historyLimit} 条',
                    style: AppTypography.aux),
                trailing: DropdownButton<int>(
                  key: const ValueKey('setting_history'),
                  value: s.historyLimit,
                  items: const [
                    DropdownMenuItem(value: 50, child: Text('50 条')),
                    DropdownMenuItem(value: 200, child: Text('200 条')),
                    DropdownMenuItem(value: 500, child: Text('500 条')),
                    DropdownMenuItem(value: 1000, child: Text('1000 条')),
                  ],
                  onChanged: (v) =>
                      context.read<SettingsStore>().setHistoryLimit(v ?? 200),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSoft),
              _row('版本', 'v0.1.0'),
              const Divider(height: 1, color: AppColors.borderSoft),
              _row('界面语言', '简体中文'),
              const Divider(height: 1, color: AppColors.borderSoft),
              _row('数据目录', r'%APPDATA%\chuyu-toolbox'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('快捷键',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              _kbd('Ctrl K', '全局搜索（任意页面）'),
              _kbd('/', '全局搜索（焦点不在输入框时）'),
              _kbd('Ctrl Enter', '发送请求（HTTP / WebSocket）'),
              _kbd('Ctrl S', '保存请求到集合（HTTP）'),
              _kbd('↑ ↓ Enter', '搜索结果选择与打开'),
              _kbd('Esc', '关闭搜索面板'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kbd(String keys, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(keys,
                style: const TextStyle(
                    fontSize: 9.5,
                    fontFamily: 'Cascadia Code',
                    color: AppColors.text2)),
          ),
          const SizedBox(width: 10),
          Text(desc, style: AppTypography.aux.copyWith(fontSize: 10.5)),
        ],
      ),
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

