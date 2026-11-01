import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 支持的源/目标格式。
enum DocFmt { txt, md, html, docx, pdf, rtf }

extension DocFmtX on DocFmt {
  String get label => switch (this) {
        DocFmt.txt => 'TXT 纯文本',
        DocFmt.md => 'Markdown',
        DocFmt.html => 'HTML 网页',
        DocFmt.docx => 'Word (DOCX)',
        DocFmt.pdf => 'PDF 文档',
        DocFmt.rtf => 'RTF 富文本',
      };
  String get ext => switch (this) {
        DocFmt.txt => 'txt',
        DocFmt.md => 'md',
        DocFmt.html => 'html',
        DocFmt.docx => 'docx',
        DocFmt.pdf => 'pdf',
        DocFmt.rtf => 'rtf',
      };
  bool get isBinary => this == DocFmt.docx || this == DocFmt.pdf;
}

class DocConvertResult {
  const DocConvertResult._({this.textOutput, this.binaryOutput, this.error});
  factory DocConvertResult.text(String s) => DocConvertResult._(textOutput: s);
  factory DocConvertResult.binary(Uint8List b) => DocConvertResult._(binaryOutput: b);
  factory DocConvertResult.fail(String msg) => DocConvertResult._(error: msg);
  final String? textOutput;
  final Uint8List? binaryOutput;
  final String? error;
  bool get ok => error == null;
}

/// 文档格式转换（TXT / MD / HTML / RTF / DOCX / PDF）。
abstract final class DocConverter {
  static const int maxBytes = 5 * 1024 * 1024;

  // ── 解析为中间模型：行列表（每行带级别的结构化文本）──

  static List<(int, String)> _parseToLines(String input, DocFmt from) {
    final text = switch (from) {
      DocFmt.md => _mdToPlainText(input),
      DocFmt.html => _htmlToPlainText(input),
      DocFmt.rtf => _rtfToPlainText(input),
      _ => input,
    };
    return [
      for (final line in text.split('\n')) (0, line),
    ];
  }

  static String _mdToPlainText(String s) {
    // 用 markdown 包渲染 HTML，再去掉标签
    final html = md.markdownToHtml(s);
    return _htmlToPlainText(html);
  }

  static String _htmlToPlainText(String s) {
    var t = s;
    t = t.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    t = t.replaceAll('</p>', '\n\n');
    t = t.replaceAll('</h[1-6]>', '\n\n');
    t = t.replaceAll('</li>', '\n');
    t = t.replaceAll(RegExp(r'<[^>]+>'), '');
    return _unescapeHtml(t).trim();
  }

  static String _unescapeHtml(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');

  static String _rtfToPlainText(String s) {
    var t = s;
    t = t.replaceAll(RegExp(r'\{\\\*?[^{}]*\}'), ''); // 去控制组
    t = t.replaceAll(RegExp(r'\\[a-z]+-?\d* ?'), ''); // 去控制字
    t = t.replaceAll('{', '').replaceAll('}', '');
    t = t.replaceAll(r'\par', '\n');
    return t.trim();
  }

  // ── 输出 ──

  static String _toTxt(List<(int, String)> lines) =>
      lines.map((l) => l.$2).join('\n');

  static String _toMd(List<(int, String)> lines) => _toTxt(lines);

  static String _toHtml(String title, List<(int, String)> lines) {
    final body = lines.map((l) {
      final text = _esc(l.$2);
      if (l.$2.startsWith('# ')) return '<h1>${text.substring(2)}</h1>';
      if (l.$2.startsWith('## ')) return '<h2>${text.substring(3)}</h2>';
      if (l.$2.startsWith('### ')) return '<h3>${text.substring(4)}</h3>';
      if (l.$2.startsWith('- ')) return '<li>${text.substring(2)}</li>';
      if (l.$2.isEmpty) return '';
      return '<p>$text</p>';
    }).join('\n');
    return '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<title>${_esc(title)}</title>
<style>
body { font-family: "Segoe UI", "Microsoft YaHei", sans-serif; max-width: 720px; margin: 40px auto; padding: 0 20px; color: #1c1f26; line-height: 1.75; }
h1, h2, h3 { color: #2f6bff; }
</style>
</head>
<body>
$body
</body>
</html>''';
  }


  static String _wrapHtml(String title, String body) => '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<title>${_esc(title)}</title>
<style>
body { font-family: "Segoe UI", "Microsoft YaHei", sans-serif; max-width: 720px; margin: 40px auto; color: #1c1f26; line-height: 1.75; }
h1, h2 { color: #2f6bff; }
</style>
</head>
<body>
$body
</body>
</html>''';

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _toRtf(List<(int, String)> lines) {
    final buf = StringBuffer();
    buf.write(r'{\rtf1\ansi\deff0');
    buf.write(r'{\fonttbl{\f0 Segoe UI;}{\f1 Microsoft YaHei;}}');
    buf.write(r'\f1\fs22 ');
    for (final (_, line) in lines) {
      buf.write(_rtfEscape(line));
      buf.write(r'\par ');
    }
    buf.write('}');
    return buf.toString();
  }

  static String _rtfEscape(String s) => s
      .replaceAll('\\', r'\\')
      .replaceAll('{', r'\{')
      .replaceAll('}', r'\}')
      .replaceAll('\t', r'\tab ')
      .codeUnits
      .map((c) => c > 127 ? '\\u$c?' : String.fromCharCode(c))
      .join();

  // ── DOCX：最小 OOXML 打包 ──

  static Uint8List _toDocx(String title, List<(int, String)> lines) {
    String escXml(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    final paragraphs = <String>[];
    for (final (_, line) in lines) {
      final heading = line.startsWith('# ');
      final subheading = line.startsWith('## ');
      final text = heading
          ? line.substring(2)
          : subheading
              ? line.substring(3)
              : line;
      final style = heading
          ? '<w:pPr><w:pStyle w:val="Heading1"/></w:pPr>'
          : subheading
              ? '<w:pPr><w:pStyle w:val="Heading2"/></w:pPr>'
              : '';
      final bold = heading || subheading
          ? '<w:rPr><w:b/><w:color w:val="2F6BFF"/></w:rPr>'
          : '';
      paragraphs.add(
          '<w:p>$style<w:r>$bold<w:t xml:space="preserve">${escXml(text)}</w:t></w:r></w:p>');
    }

    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    const rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    final document = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
${paragraphs.join('\n')}
<w:sectPr><w:pgSz w:w="11906" w:h="16838"/></w:sectPr>
</w:body>
</w:document>''';

    final archive = Archive();
    archive.addFile(ArchiveFile.string('[Content_Types].xml', contentTypes));
    archive.addFile(ArchiveFile.string('_rels/.rels', rels));
    archive.addFile(ArchiveFile.string('word/document.xml', document));

    final encoder = ZipEncoder();
    return Uint8List.fromList(encoder.encode(archive));
  }

  // ── PDF ──

  static Future<Uint8List> _toPdf(String title, List<(int, String)> lines) {

    final doc = pw.Document();


    final widgets = <pw.Widget>[];
    for (final (_, line) in lines) {
      if (line.startsWith('# ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
          child: pw.Text(line.substring(2),
              style: pw.TextStyle(
                  fontSize: 18, color: PdfColor.fromHex('#2F6BFF'))),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
          child: pw.Text(line.substring(3),
              style: pw.TextStyle(
                  fontSize: 14, color: PdfColor.fromHex('#2F6BFF'))),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 3),
          child: pw.Text(line.substring(4),
              style: pw.TextStyle(
                  fontSize: 12, color: PdfColor.fromHex('#1F4FD8'))),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
          child: pw.Row(children: [
            pw.Text('• ', style: pw.TextStyle(fontSize: 10)),
            pw.Expanded(
                child: pw.Text(line.substring(2),
                    style: pw.TextStyle(fontSize: 10))),
          ]),
        ));
      } else if (line.isNotEmpty) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(line, style: pw.TextStyle(fontSize: 10)),
        ));
      }
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => widgets,
    ));
    return doc.save();
  }

  // ── 主入口 ──

  static Future<DocConvertResult> convert(
      String input, DocFmt from, DocFmt to,
      {String title = '文档'}) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return DocConvertResult.fail('请输入内容');
    if (utf8.encode(trimmed).length > maxBytes) {
      return DocConvertResult.fail('内容超过 5 MB 上限');
    }

    final lines = _parseToLines(trimmed, from);

    try {
      if (to.isBinary) {
        if (to == DocFmt.docx) {
          return DocConvertResult.binary(_toDocx(title, lines));
        }
        final pdfBytes = await _toPdf(title, lines);
        return DocConvertResult.binary(pdfBytes);
      }
      final text = switch (to) {
        DocFmt.txt => _toTxt(lines),
        DocFmt.md => _toMd(lines),
        DocFmt.html => from == DocFmt.md
            ? _wrapHtml(title, md.markdownToHtml(trimmed))
            : _toHtml(title, lines),
        DocFmt.rtf => _toRtf(lines),
        _ => throw StateError('unreachable'),
      };
      return DocConvertResult.text(text);
    } catch (e) {
      return DocConvertResult.fail('${to.label} 输出失败：$e');
    }
  }
}






