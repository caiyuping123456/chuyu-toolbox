import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../json_formatter.dart';

/// JSON 格式化工作区（M5-3）：左输入右输出，格式化 / 压缩 / 校验 / 排序 / 复制。
class JsonFormatPage extends StatefulWidget {
  const JsonFormatPage({super.key});

  @override
  State<JsonFormatPage> createState() => _JsonFormatPageState();
}

class _JsonFormatPageState extends State<JsonFormatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _inScroll = ScrollController();
  final ScrollController _outScroll = ScrollController();

  JsonFormatResult? _result;
  int _indent = 2;
  bool _sortKeys = false;
  String? _notice;

  static const String _sample = '''
{"code":0,"message":"ok","data":{"total":128,"list":[{"id":1,"name":"张三","role":"admin"},{"id":2,"name":"李四","role":"user"}]}}
''';

  @override
  void dispose() {
    _input.dispose();
    _inScroll.dispose();
    _outScroll.dispose();
    super.dispose();
  }

  void _run({bool minify = false}) {
    final r = minify
        ? JsonFormatter.minify(_input.text)
        : JsonFormatter.format(_input.text,
            indent: _indent, sortKeys: _sortKeys);
    setState(() {
      _result = r;
      _notice = null;
    });
  }

  void _validate() {
    final r = JsonFormatter.validate(_input.text);
    setState(() {
      _result = r;
      _notice = r.ok ? 'JSON 合法' : null;
    });
  }

  Future<void> _copy() async {
    final text = _result?.output;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
          content: Text('已复制格式化结果'),
          duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        Expanded(
          child: Container(
            color: AppColors.bg,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _toolbar(),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _inputCard()),
                      const SizedBox(width: 10),
                      Expanded(child: _outputCard()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      );

  Widget _header() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.data_object,
                size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('JSON 格式化',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5-3',
              color: AppColors.accent, background: AppColors.accentSoft),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('格式化 · 压缩 · 校验 · 排序 · 复制',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.aux),
          ),
          const Text('上限 2 MB', style: AppTypography.aux),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final canOut = _result?.ok == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: _cardDecoration,
      child: Row(
        children: [
          _ActionButton(
            key: const ValueKey('json_format'),
            icon: Icons.format_align_left,
            label: '格式化',
            primary: true,
            onTap: _run,
          ),
          const SizedBox(width: 6),
          _ActionButton(
            key: const ValueKey('json_minify'),
            icon: Icons.compress,
            label: '压缩',
            onTap: () => _run(minify: true),
          ),
          const SizedBox(width: 6),
          _ActionButton(
            key: const ValueKey('json_validate'),
            icon: Icons.fact_check_outlined,
            label: '校验',
            onTap: _validate,
          ),
          const SizedBox(width: 10),
          const _Divider(),
          const SizedBox(width: 10),
          const Text('缩进', style: AppTypography.aux),
          const SizedBox(width: 6),
          _segmented<int>(
            value: _indent,
            options: const [(2, '2 空格'), (4, '4 空格')],
            onChanged: (v) => setState(() {
              _indent = v;
              if (_result?.ok == true) _run();
            }),
          ),
          const SizedBox(width: 10),
          _CheckChip(
            key: const ValueKey('json_sort'),
            label: '排序键',
            value: _sortKeys,
            onChanged: (v) => setState(() {
              _sortKeys = v;
              if (_result?.ok == true) _run();
            }),
          ),
          const Spacer(),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(_notice!,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.ok)),
            ),
          _ActionButton(
            key: const ValueKey('json_sample'),
            icon: Icons.auto_awesome_outlined,
            label: '示例',
            onTap: () => setState(() {
              _input.text = _sample.trim();
              _result = JsonFormatter.format(_input.text);
              _notice = null;
            }),
          ),
          const SizedBox(width: 6),
          _ActionButton(
            key: const ValueKey('json_clear'),
            icon: Icons.delete_sweep_outlined,
            label: '清空',
            onTap: () => setState(() {
              _input.clear();
              _result = null;
              _notice = null;
            }),
          ),
          const SizedBox(width: 6),
          _ActionButton(
            key: const ValueKey('json_copy'),
            icon: Icons.copy_all_outlined,
            label: '复制',
            enabled: canOut,
            onTap: _copy,
          ),
        ],
      ),
    );
  }

  Widget _inputCard() {
    final bytes = _input.text.isEmpty ? 0 : _input.text.length;
    return Container(
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _paneHead('输入', trailing: '${_fmtSize(bytes)} · 字符 ${_input.text.length}'),
          const Divider(height: 1),
          Expanded(
            child: TextField(
              key: const ValueKey('json_input'),
              controller: _input,
              scrollController: _inScroll,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (_) => setState(() {}),
              style: AppTypography.code.copyWith(fontSize: 11),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.all(12),
                hintText: '粘贴 JSON，例如 {"a":1}',
                hintStyle: TextStyle(fontSize: 11, color: AppColors.text4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputCard() {
    final r = _result;
    final ok = r?.ok == true;
    return Container(
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _paneHead(
            '输出',
            trailing: ok
                ? '${_fmtSize(r!.outputBytes)} · ${r.output!.split('\n').length} 行'
                : '—',
            trailingColor: ok ? AppColors.text3 : AppColors.err,
          ),
          const Divider(height: 1),
          Expanded(
            child: r == null
                ? _empty('点击「格式化」查看结果')
                : r.ok
                    ? SingleChildScrollView(
                        controller: _outScroll,
                        padding: const EdgeInsets.all(12),
                        child: SelectableText.rich(
                          _highlight(r.output!),
                          style: AppTypography.code.copyWith(fontSize: 11),
                        ),
                      )
                    : _errorView(r),
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.data_object, size: 26, color: AppColors.text4),
          const SizedBox(height: 8),
          Text(text,
              style: AppTypography.aux.copyWith(color: AppColors.text4)),
        ],
      ),
    );
  }

  Widget _errorView(JsonFormatResult r) {
    final where = r.line == null
        ? ''
        : '第 ${r.line} 行${r.column == null ? '' : '，第 ${r.column} 列'}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 14, color: AppColors.err),
              const SizedBox(width: 6),
              const Text('JSON 不合法',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.err)),
            ],
          ),
          const SizedBox(height: 6),
          if (where.isNotEmpty)
            Text(where,
                style: const TextStyle(fontSize: 10, color: AppColors.text2)),
          const SizedBox(height: 4),
          Text(r.error!,
              style: const TextStyle(fontSize: 10, color: AppColors.text3)),
        ],
      ),
    );
  }

  Widget _paneHead(String title,
      {String? trailing, Color? trailingColor}) {
    return SizedBox(
      height: 34,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2)),
            const Spacer(),
            if (trailing != null)
              Text(trailing,
                  style: TextStyle(
                      fontSize: 9.5, color: trailingColor ?? AppColors.text4)),
          ],
        ),
      ),
    );
  }

  /// JSON 着色（键紫 / 字符串绿 / 数字橙 / 布尔蓝 / 标点灰）。
  TextSpan _highlight(String pretty) {
    final base = AppTypography.code.copyWith(fontSize: 11);
    final token = RegExp(
        r'"(?:[^"\\]|\\.)*"|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|\b(?:true|false|null)\b');
    final spans = <InlineSpan>[];
    var pos = 0;
    for (final m in token.allMatches(pretty)) {
      if (m.start > pos) {
        spans.add(TextSpan(
            text: pretty.substring(pos, m.start),
            style: base.copyWith(color: AppColors.jsonPunct)));
      }
      final t = m.group(0)!;
      Color color;
      if (t.startsWith('"')) {
        final next = pretty.substring(m.end).trimLeft();
        color = next.startsWith(':') ? AppColors.jsonKey : AppColors.jsonStr;
      } else if (t == 'true' || t == 'false' || t == 'null') {
        color = AppColors.put;
      } else {
        color = AppColors.jsonNum;
      }
      spans.add(TextSpan(text: t, style: base.copyWith(color: color)));
      pos = m.end;
    }
    if (pos < pretty.length) {
      spans.add(TextSpan(
          text: pretty.substring(pos),
          style: base.copyWith(color: AppColors.jsonPunct)));
    }
    return TextSpan(children: spans);
  }

  Widget _segmented<T>({
    required T value,
    required List<(T, String)> options,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            GestureDetector(
              onTap: () => onChanged(o.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == o.$1 ? AppColors.panel : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: value == o.$1
                          ? AppColors.borderSoft
                          : Colors.transparent),
                ),
                child: Text(o.$2,
                    style: TextStyle(
                        fontSize: 9.5,
                        height: 1.4,
                        fontWeight: value == o.$1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: value == o.$1
                            ? AppColors.text
                            : AppColors.text3)),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fg = !enabled
        ? AppColors.text4
        : primary
            ? Colors.white
            : AppColors.text2;
    return SizedBox(
      height: 28,
      child: Material(
        color: !enabled
            ? AppColors.fill
            : primary
                ? AppColors.accent
                : AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(
              color: primary && enabled
                  ? AppColors.accent
                  : AppColors.border),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: fg),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            primary ? FontWeight.w600 : FontWeight.w400,
                        color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckChip extends StatelessWidget {
  const _CheckChip({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Material(
        color: value ? AppColors.accentSoft : AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
              color: value ? AppColors.accentBorder : AppColors.border),
        ),
        child: InkWell(
          onTap: () => onChanged(!value),
          customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(value ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 12,
                    color: value ? AppColors.accent : AppColors.text4),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                            value ? FontWeight.w600 : FontWeight.w400,
                        color: value ? AppColors.accentDark : AppColors.text3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 16, color: AppColors.border);
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.color, this.background});

  final String text;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          height: 1.5,
          color: color ?? AppColors.text3,
          fontWeight: color == null ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
    );
  }
}
