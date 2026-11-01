import 'package:flutter/material.dart';

import '../../../core/export_service.dart';
import '../../../core/theme.dart';
import '../doc_converter.dart';

class DocConvertPage extends StatefulWidget {
  const DocConvertPage({super.key});
  @override
  State<DocConvertPage> createState() => _DocConvertPageState();
}

class _DocConvertPageState extends State<DocConvertPage> {
  DocFmt _from = DocFmt.md;
  DocFmt _to = DocFmt.docx;
  final _input = TextEditingController();
  String? _error;
  String? _outputPath;
  bool _busy = false;
  String _binaryPreview = '';

  static const _sample = '''# ChuYu 万能工具箱

## 功能清单

- HTTP 请求测试
- WebSocket 调试
- 端口连通检测
- JSON 格式化

这是简介段落。支持 **粗体** 与*斜体*。
''';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; _outputPath = null; _binaryPreview = ''; });
    final r = await DocConverter.convert(_input.text, _from, _to, title: 'ChuYu 文档');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) {
        if (r.textOutput != null) {
          _binaryPreview = r.textOutput!;
          if (r.textOutput!.length < 3000) _binaryPreview = r.textOutput!;
        } else if (r.binaryOutput != null) {
          _binaryPreview = '${r.binaryOutput!.length} 字节（二进制 ${_to.ext}）';
        }
      } else {
        _error = r.error;
      }
    });
  }

  Future<void> _saveFile() async {
    if (_binaryPreview.isEmpty && _error == null) return;
    final r = await ExportService.exportText(
        _binaryPreview, 'converted', _to.ext);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(r.ok ? '已保存到 ${r.path}' : r.error!),
          duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _header(),
      Expanded(
        child: Container(
          color: AppColors.bg,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _formatBar(),
            const SizedBox(height: 10),
            Expanded(child: _contentArea()),
          ]),
        ),
      ),
    ]);
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      );

  Widget _header() => Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: AppColors.panel,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.description_outlined, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('文档转换', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5-10', color: AppColors.accent, background: AppColors.accentSoft),
          const Spacer(),
          const Text('TXT / MD / HTML / RTF / DOCX / PDF', style: AppTypography.aux),
        ]),
      );

  Widget _formatBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: _cardDecoration,
      child: Row(children: [
        _selector('从', _from, (v) => setState(() => _from = v)),
        const Icon(Icons.arrow_forward, size: 16, color: AppColors.accent),
        _selector('到', _to, (v) => setState(() => _to = v)),
        const SizedBox(width: 10),
        _Btn(key: const ValueKey('doc_convert'), label: _busy ? '转换中…' : '转换', primary: true, onTap: _convert, enabled: !_busy),
        const Spacer(),
        if (_outputPath != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('已导出 $_outputPath',
                style: const TextStyle(fontSize: 9.5, color: AppColors.ok)),
          ),
        _Btn(key: const ValueKey('doc_sample'), label: '示例', onTap: () => setState(() => _input.text = _sample)),
        const SizedBox(width: 6),
        _Btn(label: '清空', onTap: () => setState(() { _input.clear(); _error = null; _outputPath = null; _binaryPreview = ''; })),
      ]),
    );
  }

  Widget _selector(String label, DocFmt value, ValueChanged<DocFmt> on) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: AppTypography.aux),
      const SizedBox(width: 6),
      Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadius.control)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<DocFmt>(
            value: value, isDense: true,
            icon: const Icon(Icons.expand_more, size: 14, color: AppColors.text3),
            style: const TextStyle(fontSize: 10.5, color: AppColors.text2),
            items: DocFmt.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
            onChanged: (v) => on(v ?? value),
          ),
        ),
      ),
      const SizedBox(width: 4),
    ]);
  }

  Widget _contentArea() {
    return Row(children: [
      Expanded(child: _pane('输入（${_from.label}）', true, 'doc_input')),
      const SizedBox(width: 10),
      Expanded(child: _pane('输出（${_to.label}）', false, 'doc_output')),
    ]);
  }

  Widget _pane(String title, bool editable, String key) {
    return Container(
      decoration: _cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 30,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2)))),
        ),
        const Divider(height: 1),
        Expanded(
          child: editable
              ? TextField(
                  key: ValueKey(key),
                  controller: _input,
                  maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
                  style: AppTypography.code.copyWith(fontSize: 11),
                  decoration: InputDecoration(
                    border: InputBorder.none, isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    hintText: '粘贴 ${_from.label} 内容…',
                    hintStyle: const TextStyle(fontSize: 10.5, color: AppColors.text4)),
                )
              : _outputPane(),
        ),
        if (!editable && _outputPath != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity, height: 30,
              child: FilledButton(
                onPressed: _saveFile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('保存到下载目录')),
            ),
          ),
      ]),
    );
  }

  Widget _outputPane() {
    if (_busy) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
    }
    if (_error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Text(_error!, style: const TextStyle(fontSize: 10.5, color: AppColors.err)));
    }
    if (_outputPath != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_outline, size: 28, color: AppColors.ok),
        const SizedBox(height: 8),
        Text('已导出到\n$_outputPath', textAlign: TextAlign.center, style: AppTypography.aux),
      ]));
    }
    if (_binaryPreview.isEmpty) {
      return Center(child: Text('点击「转换」查看结果', style: AppTypography.aux.copyWith(color: AppColors.text4)));
    }
    if (_binaryPreview.contains('字节')) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(_to == DocFmt.pdf ? Icons.picture_as_pdf : Icons.description, size: 32, color: AppColors.accent),
        const SizedBox(height: 8),
        Text(_binaryPreview, style: AppTypography.aux),
        Text('点击下方按钮保存到下载目录', style: AppTypography.aux.copyWith(color: AppColors.text4)),
      ]));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(_binaryPreview, style: AppTypography.code.copyWith(fontSize: 10.5)));
  }
}

class _Btn extends StatelessWidget {
  const _Btn({super.key, required this.label, required this.onTap, this.primary = false, this.enabled = true});
  final String label; final VoidCallback onTap; final bool primary; final bool enabled;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: Material(
      color: !enabled ? AppColors.fill : primary ? AppColors.accent : AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: BorderSide(color: primary && enabled ? AppColors.accent : AppColors.border)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Center(child: Text(label, style: TextStyle(
            fontSize: 10.5, fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
            color: !enabled ? AppColors.text4 : primary ? Colors.white : AppColors.text2)))),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.color, this.background});
  final String text; final Color? color; final Color? background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: background, borderRadius: BorderRadius.circular(AppRadius.badge),
      border: Border.all(color: AppColors.borderSoft)),
    child: Text(text, style: TextStyle(fontSize: 9, height: 1.5, color: color ?? AppColors.text3,
        fontWeight: color == null ? FontWeight.w400 : FontWeight.w600)),
  );
}
