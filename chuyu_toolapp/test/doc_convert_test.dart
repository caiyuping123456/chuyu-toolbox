import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/modules/doc_convert/doc_converter.dart';

void main() {
  const md = '# 标题\n## 子标题\n- 项目一\n- 项目二\n正文段落。\n';
  const html = '<html><body><h1>标题</h1><p>段落</p></body></html>';

  test('MD → TXT：去标记保留文本', () async {
    final r = await DocConverter.convert(md, DocFmt.md, DocFmt.txt);
    expect(r.ok, isTrue);
    expect(r.textOutput, contains('标题'));
    expect(r.textOutput, contains('项目一'));
    expect(r.textOutput, isNot(contains('#')));
  });

  test('MD → HTML：输出完整网页', () async {
    final r = await DocConverter.convert(md, DocFmt.md, DocFmt.html);
    expect(r.ok, isTrue);
    expect(r.textOutput, contains('<!DOCTYPE html>'));
    expect(r.textOutput, contains('<h1>'));
    expect(r.textOutput, contains('<li>'));
  });

  test('HTML → TXT：去标签', () async {
    final r = await DocConverter.convert(html, DocFmt.html, DocFmt.txt);
    expect(r.ok, isTrue);
    expect(r.textOutput, contains('标题'));
    expect(r.textOutput, contains('段落'));
    expect(r.textOutput, isNot(contains('<h1>')));
  });

  test('MD → RTF：控制字 + 中文转义', () async {
    final r = await DocConverter.convert(md, DocFmt.md, DocFmt.rtf);
    expect(r.ok, isTrue);
    expect(r.textOutput, startsWith(r'{\rtf1'));
    expect(r.textOutput, contains(r'\par'));
  });

  test('MD → DOCX：ZIP 二进制（PK 头）', () async {
    final r = await DocConverter.convert(md, DocFmt.md, DocFmt.docx);
    expect(r.ok, isTrue);
    expect(r.binaryOutput, isNotNull);
    // ZIP magic
    expect(r.binaryOutput![0], 0x50);
    expect(r.binaryOutput![1], 0x4B);
  });

  test('MD → PDF：二进制（%PDF 头）', () async {
    final r = await DocConverter.convert('# Hello\n\nWorld.', DocFmt.md, DocFmt.pdf);
    expect(r.ok, isTrue);
    expect(r.binaryOutput, isNotNull);
    final head = String.fromCharCodes(r.binaryOutput!.take(4));
    expect(head, '%PDF');
  });

  test('TXT → MD：直通', () async {
    final r = await DocConverter.convert('你好世界\n第二行', DocFmt.txt, DocFmt.md);
    expect(r.ok, isTrue);
    expect(r.textOutput, contains('你好世界'));
  });

  test('空输入报错', () async {
    final r = await DocConverter.convert('', DocFmt.txt, DocFmt.md);
    expect(r.ok, isFalse);
    expect(r.error, contains('请输入'));
  });
}
