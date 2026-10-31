import 'package:flutter/material.dart';
import '../toolbox_module.dart';
import 'ui/base64_page.dart';

class Base64CodecModule extends ToolboxModule {
  const Base64CodecModule();
  @override String get id => 'base64';
  @override String get name => 'Base64 编解码';
  @override String get category => '编码转换';
  @override String get summary => '文本与 Base64 互转';
  @override List<String> get keywords => const ['base64', '编码', '解码', 'b64'];
  @override String get version => '1.0.0';
  @override IconData get icon => Icons.terminal;
  @override Widget buildPage(BuildContext context, {Object? intent}) => const Base64Page();
}
