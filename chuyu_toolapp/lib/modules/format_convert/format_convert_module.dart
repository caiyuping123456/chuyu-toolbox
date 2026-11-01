import 'package:flutter/material.dart';
import '../toolbox_module.dart';
import 'ui/format_convert_page.dart';

class FormatConvertModule extends ToolboxModule {
  const FormatConvertModule();
  @override String get id => 'format_convert';
  @override String get name => '格式转换';
  @override String get category => '编码转换';
  @override String get summary => 'JSON / YAML / CSV / XML 互转';
  @override List<String> get keywords => const ['yaml', 'csv', 'xml', '转换', '格式'];
  @override String get version => '1.0.0';
  @override IconData get icon => Icons.swap_horiz;
  @override Widget buildPage(BuildContext context, {Object? intent}) => const FormatConvertPage();
}
