import 'package:flutter/material.dart';
import '../toolbox_module.dart';
import 'ui/hash_page.dart';

class HashCalcModule extends ToolboxModule {
  const HashCalcModule();
  @override String get id => 'hash';
  @override String get name => '哈希计算';
  @override String get category => '开发辅助';
  @override String get summary => 'MD5 / SHA 系列摘要';
  @override List<String> get keywords => const ['md5', 'sha', '哈希', '摘要'];
  @override String get version => '1.0.0';
  @override IconData get icon => Icons.fingerprint;
  @override Widget buildPage(BuildContext context, {Object? intent}) => const HashPage();
}
