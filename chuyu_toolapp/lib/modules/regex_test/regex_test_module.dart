import 'package:flutter/material.dart';
import '../toolbox_module.dart';
import 'ui/regex_page.dart';

class RegexTestModule extends ToolboxModule {
  const RegexTestModule();
  @override String get id => 'regex_test';
  @override String get name => '正则测试';
  @override String get category => '开发辅助';
  @override String get summary => '正则匹配、提取与替换';
  @override List<String> get keywords => const ['regex', '正则', '匹配', '替换'];
  @override String get version => '1.0.0';
  @override IconData get icon => Icons.rule;
  @override Widget buildPage(BuildContext context, {Object? intent}) => const RegexPage();
}
