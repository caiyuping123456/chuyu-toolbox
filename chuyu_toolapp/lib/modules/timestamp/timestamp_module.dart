import 'package:flutter/material.dart';
import '../toolbox_module.dart';
import 'ui/timestamp_page.dart';

class TimestampModule extends ToolboxModule {
  const TimestampModule();
  @override String get id => 'timestamp';
  @override String get name => '时间戳转换';
  @override String get category => '编码转换';
  @override String get summary => 'Unix 时间戳与日期互转';
  @override List<String> get keywords => const ['时间戳', 'unix', 'date', '日期'];
  @override String get version => '1.0.0';
  @override IconData get icon => Icons.schedule;
  @override Widget buildPage(BuildContext context, {Object? intent}) => const TimestampPage();
}
