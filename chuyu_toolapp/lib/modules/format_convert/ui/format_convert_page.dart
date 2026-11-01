import 'package:flutter/material.dart';

import '../../../core/export_service.dart';
import '../../../core/theme.dart';
import '../format_converter.dart';

class FormatConvertPage extends StatefulWidget {
  const FormatConvertPage({super.key});
  @override
  State<FormatConvertPage> createState() => _FormatConvertPageState();
}

class _FormatConvertPageState extends State<FormatConvertPage> {
  Fmt _from = Fmt.json;
  Fmt _to = Fmt.yaml;
  bool _sortKeys = false;
  final _input = TextEditingController();
  final _output = TextEditingController();
  String? _error;
  String? _notice;

  static const _sample = '{"name":"ChuYu","tags":["dev","tool"],"count":9}';

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _convert() {
    final r = FormatConverter.convert(_input.text, _from, _to, sortKeys: _sortKeys);
    setState(() {
      _output.text = r.output ?? '';
      _error = r.error;
      _notice = null;
    });
  }

  void _swap() => setState(() {
        final t = _from;
        _from = _to;
        _to = t;
        final text = _input.text;
        _input.text = _output.text;
        _output.text = text;
        _error = null;
        _notice = null;
      });

  Future<void> _export() async {
    if (_output.text.isEmpty) return;
    final r = await ExportService.exportText(_output.text, 'converted', _to.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(r.ok ? '已导出到 ${r.path}' : r.error!),
          duration: const Duration(seconds: 3)));
  }

  InputDecoration get _deco => InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
        hintStyle: const TextStyle(fontSize: 10.5, color: AppColors.text4),
      );

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      );

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
            Expanded(
              child: Row(children: [
                Expanded(child: _pane('输入（${_from.label}）', editable: true, key: 'fmt_input')),
                const SizedBox(width: 10),
                Expanded(child: _pane('输出（${_to.label}）', editable: false, key: 'fmt_output')),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }

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
            child: const Icon(Icons.swap_horiz, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('格式转换', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5-9', color: AppColors.accent, background: AppColors.accentSoft),
          const Spacer(),
          const Text('JSON / YAML / CSV / XML · 以 JSON 为中间模型', style: AppTypography.aux),
        ]),
      );

  Widget _formatBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: _cardDecoration,
      child: Row(children: [
        _fmtSelector('从', _from, (v) => setState(() => _from = v)),
        IconButton(
          key: const ValueKey('fmt_swap'),
          icon: const Icon(Icons.swap_horiz, size: 18),
          color: AppColors.accent,
          onPressed: _swap,
          tooltip: '交换方向',
        ),
        _fmtSelector('到', _to, (v) => setState(() => _to = v)),
        const SizedBox(width: 12),
        _Btn(key: const ValueKey('fmt_convert'), label: '转换', primary: true, onTap: _convert),
        const SizedBox(width: 6),
        _CheckChip(label: '排序键', value: _sortKeys, onChanged: (v) => setState(() => _sortKeys = v)),
        const Spacer(),
        if (_notice != null)
          Text(_notice!, style: const TextStyle(fontSize: 9.5, color: AppColors.ok)),
        const SizedBox(width: 6),
        _Btn(key: const ValueKey('fmt_sample'), label: '示例', onTap: () => setState(() => _input.text = _sample)),
        const SizedBox(width: 6),
        _Btn(label: '清空', onTap: () => setState(() { _input.clear(); _output.clear(); _error = null; _notice = null; })),
        const SizedBox(width: 6),
        _Btn(key: const ValueKey('fmt_export'), label: '导出', onTap: _export),
      ]),
    );
  }

  Widget _fmtSelector(String label, Fmt value, ValueChanged<Fmt> on) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: AppTypography.aux),
      const SizedBox(width: 6),
      Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadius.control)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Fmt>(
            key: ValueKey('fmt_from_$label'),
            value: value,
            isDense: true,
            icon: const Icon(Icons.expand_more, size: 14, color: AppColors.text3),
            style: const TextStyle(fontSize: 10.5, color: AppColors.text2),
            items: Fmt.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
            onChanged: (v) => on(v ?? value),
          ),
        ),
      ),
    ]);
  }

  Widget _pane(String title, {required bool editable, String? key}) {
    final hasError = !editable && _error != null;
    return Container(
      decoration: _cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 30,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2)),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: editable
              ? TextField(
                  key: ValueKey(key),
                  controller: _input,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTypography.code.copyWith(fontSize: 11),
                  decoration: _deco.copyWith(hintText: '粘贴 ${_from.label} 内容…'),
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  child: hasError
                      ? SingleChildScrollView(child: Text(_error!, style: const TextStyle(fontSize: 10.5, color: AppColors.err)))
                      : _output.text.isEmpty
                          ? Text('点击「转换」查看结果', style: AppTypography.aux.copyWith(color: AppColors.text4))
                          : SingleChildScrollView(
                              child: SelectableText(_output.text,
                                  style: AppTypography.code.copyWith(fontSize: 11)),
                            ),
                ),
        ),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({super.key, required this.label, required this.onTap, this.primary = false});
  final String label; final VoidCallback onTap; final bool primary;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: Material(
      color: primary ? AppColors.accent : AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: BorderSide(color: primary ? AppColors.accent : AppColors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Center(child: Text(label, style: TextStyle(
            fontSize: 10.5, fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
            color: primary ? Colors.white : AppColors.text2)))),
      ),
    ),
  );
}

class _CheckChip extends StatelessWidget {
  const _CheckChip({required this.label, required this.value, required this.onChanged});
  final String label; final bool value; final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 26,
    child: Material(
      color: value ? AppColors.accentSoft : AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: value ? AppColors.accentBorder : AppColors.border)),
      child: InkWell(
        onTap: () => onChanged(!value),
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(value ? Icons.check_box : Icons.check_box_outline_blank,
                size: 12, color: value ? AppColors.accent : AppColors.text4),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 9.5,
                color: value ? AppColors.accentDark : AppColors.text3,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
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

