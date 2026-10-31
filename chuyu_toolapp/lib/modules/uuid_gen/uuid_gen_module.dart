import 'package:flutter/material.dart';
import '../toolbox_module.dart';
import 'ui/uuid_page.dart';

class UuidGenModule extends ToolboxModule {
  const UuidGenModule();
  @override String get id => 'uuid';
  @override String get name => 'UUID 生成';
  @override String get category => '开发辅助';
  @override String get summary => '批量生成 UUID v4';
  @override List<String> get keywords => const ['uuid', 'guid', '唯一'];
  @override String get version => '1.0.0';
  @override IconData get icon => Icons.vpn_key_outlined;
  @override Widget buildPage(BuildContext context, {Object? intent}) => const UuidPage();
}
