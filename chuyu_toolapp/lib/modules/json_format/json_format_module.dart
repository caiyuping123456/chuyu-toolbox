import 'package:flutter/material.dart';

import '../toolbox_module.dart';
import 'ui/json_format_page.dart';

/// JSON 格式化模块（M5-3）。
class JsonFormatModule extends ToolboxModule {
  const JsonFormatModule();

  @override
  String get id => 'json_fmt';
  @override
  String get name => 'JSON 格式化';
  @override
  String get category => '编码转换';
  @override
  String get summary => '格式化、校验与排序';
  @override
  List<String> get keywords =>
      const ['json', '格式化', '校验', '压缩', 'beautify'];
  @override
  String get version => '1.0.0';
  @override
  bool get enabled => true;
  @override
  IconData get icon => Icons.data_object;

  @override
  Widget buildPage(BuildContext context, {Object? intent}) {
    return const JsonFormatPage();
  }
}
