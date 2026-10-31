import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/module_registry.dart';
import '../core/theme.dart';
import 'app_state.dart';
import 'home_page.dart';
import 'module_manager_page.dart';
import 'nav_sidebar.dart';
import 'search_palette.dart';
import 'settings_page.dart';

/// 应用壳：标题栏 38 + （侧栏 216 | 内容）+ 状态栏 24（SPEC §4.1 / §7.1）。
class ToolboxApp extends StatelessWidget {
  const ToolboxApp({super.key, required this.registry});

  final ModuleRegistry registry;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ModuleRegistry>.value(value: registry),
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'ChuYu 万能工具箱',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _Shell(),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final registry = context.read<ModuleRegistry>();
    final enabled = registry.enabledModules;

    var moduleIndex = -1;
    if (state.page == ShellPage.module) {
      moduleIndex = enabled.indexWhere((m) => m.id == state.activeModuleId);
    }
    final index = switch (state.page) {
      ShellPage.home => 0,
      ShellPage.module => moduleIndex >= 0 ? 1 + moduleIndex : 0,
      ShellPage.manager => 1 + enabled.length,
      ShellPage.settings => 2 + enabled.length,
    };

    final pages = <Widget>[
      const HomePage(),
      for (final m in enabled)
        m.buildPage(
          context,
          intent: state.page == ShellPage.module ? state.moduleIntent : null,
        ),
      const ModuleManagerPage(),
      const SettingsPage(),
    ];

    final pageTitle = switch (state.page) {
      ShellPage.home => '首页',
      ShellPage.module =>
        registry.byId(state.activeModuleId ?? '')?.name ?? '模块',
      ShellPage.manager => '模块管理',
      ShellPage.settings => '设置',
    };

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            () => state.openSearch(),
        const SingleActivator(LogicalKeyboardKey.slash): () {
          // 焦点在输入框时输入普通字符，不触发搜索（SPEC §4.5）。
          if (!_isTextEditing()) state.openSearch();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              _TitleBar(pageTitle: pageTitle),
              Expanded(
                child: Stack(
                  children: [
                    Row(
                      children: [
                        const NavSidebar(),
                        Container(width: 1, color: AppColors.border),
                        Expanded(
                            child: IndexedStack(index: index, children: pages)),
                      ],
                    ),
                    if (state.searchOpen) const SearchPalette(),
                  ],
                ),
              ),
              _StatusBar(
                  moduleActive:
                      state.page == ShellPage.module ? pageTitle : null),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isTextEditing() {
  final focus = FocusManager.instance.primaryFocus;
  final ctx = focus?.context;
  return ctx != null && ctx.widget is EditableText;
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.pageTitle});

  final String pageTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'CY',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2),
            ),
          ),
          const SizedBox(width: 9),
          const Text('ChuYu 万能工具箱',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(width: 6),
          Text('· $pageTitle', style: AppTypography.aux),
          const Spacer(),
          const Text('v0.1.0', style: AppTypography.aux),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.moduleActive});

  final String? moduleActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                const BoxDecoration(color: AppColors.ok, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text('就绪',
              style: AppTypography.aux
                  .copyWith(fontSize: 10.5, color: AppColors.text2)),
          if (moduleActive != null) ...[
            const SizedBox(width: 12),
            Text('模块：$moduleActive · 超时 30 s · UTF-8', style: AppTypography.aux),
          ],
          const Spacer(),
          const Text('本地运行 · 无联网 · v0.1.0', style: AppTypography.aux),
        ],
      ),
    );
  }
}
