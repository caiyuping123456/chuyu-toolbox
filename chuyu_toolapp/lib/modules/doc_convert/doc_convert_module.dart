import 'package:flutter/material.dart';
import '../toolbox_module.dart';
import 'ui/doc_convert_page.dart';

class DocConvertModule extends ToolboxModule {
  const DocConvertModule();
  @override String get id => 'doc_convert';
  @override String get name => '文档转换';
  @override String get category => '编码转换';
  @override String get summary => 'TXT/MD/HTML/RTF/DOCX/PDF 互转';
  @override List<String> get keywords => const ['doc', 'word', 'pdf', 'markdown', '文档', '转换'];
  @override String get version => '1.0.0';
  @override IconData get icon => Icons.description_outlined;
  @override Widget buildPage(BuildContext context, {Object? intent}) => const DocConvertPage();
}
