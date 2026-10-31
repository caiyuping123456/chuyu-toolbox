import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../base64_codec.dart';

/// Base64 编解码工作区（文本 ↔ Base64，UTF-8）。
class Base64Page extends StatefulWidget {
  const Base64Page({super.key});

  @override
  State<Base64Page> createState() => _Base64PageState();
}

class _Base64PageState extends State<Base64Page> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  bool _urlSafe = false;

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  void _runEncode() {
    final r = Base64CodecX.encode(_input.text, urlSafe: _urlSafe);
    setState(() {
      _output.text = r.output ?? '';
      if (!r.ok) _snack(r.error!);
    });
  }

  void _runDecode() {
    final r = Base64CodecX.decode(_input.text);
    setState(() {
      _output.text = r.output ?? '';
      if (!r.ok) _snack(r.error!);
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
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
                    children: [
                      Expanded(child: _pane('输入', _input, key: 'b64_input')),
                      const SizedBox(width: 10),
                      Expanded(child: _pane('输出', _output, key: 'b64_output', readOnly: true)),
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
            child: const Icon(Icons.terminal, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('Base64 编解码', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5-4', color: AppColors.accent, background: AppColors.accentSoft),
          const Spacer(),
          const Text('UTF-8 · 标准 / URL-Safe', style: AppTypography.aux),
        ]),
      );

  Widget _toolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: _cardDecoration,
      child: Row(children: [
        _Btn(key: const ValueKey('b64_encode'), label: '编码 →', primary: true, onTap: _runEncode),
        const SizedBox(width: 6),
        _Btn(key: const ValueKey('b64_decode'), label: '← 解码', onTap: _runDecode),
        const SizedBox(width: 6),
        _Btn(label: '交换 ⇄', onTap: () => setState(() {
          final t = _input.text; _input.text = _output.text; _output.text = t;
        })),
        const SizedBox(width: 10),
        SizedBox(
          height: 26,
          child: Material(
            color: _urlSafe ? AppColors.accentSoft : AppColors.panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: _urlSafe ? AppColors.accentBorder : AppColors.border),
            ),
            child: InkWell(
              onTap: () => setState(() => _urlSafe = !_urlSafe),
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_urlSafe ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 12, color: _urlSafe ? AppColors.accent : AppColors.text4),
                  const SizedBox(width: 4),
                  Text('URL-Safe',
                      style: TextStyle(fontSize: 9.5, color: _urlSafe ? AppColors.accentDark : AppColors.text3)),
                ]),
              ),
            ),
          ),
        ),
        const Spacer(),
        _Btn(label: '示例', onTap: () => setState(() => _input.text = 'ChuYu 万能工具箱')),
        const SizedBox(width: 6),
        _Btn(label: '清空', onTap: () => setState(() { _input.clear(); _output.clear(); })),
        const SizedBox(width: 6),
        _Btn(label: '复制', onTap: () async {
          if (_output.text.isEmpty) return;
          await Clipboard.setData(ClipboardData(text: _output.text));
          if (mounted) _snack('已复制');
        }),
      ]),
    );
  }

  Widget _pane(String title, TextEditingController ctrl, {String? key, bool readOnly = false}) {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TextField(
              key: key == null ? null : ValueKey(key),
              controller: ctrl,
              readOnly: readOnly,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: AppTypography.code.copyWith(fontSize: 11),
              decoration: InputDecoration(
                border: InputBorder.none, isDense: true,
                contentPadding: const EdgeInsets.all(12),
                hintText: readOnly ? '结果' : '输入文本或 Base64',
                hintStyle: const TextStyle(fontSize: 11, color: AppColors.text4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({super.key, required this.label, required this.onTap, this.primary = false});
  final String label;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Material(
        color: primary ? AppColors.accent : AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: primary ? AppColors.accent : AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(label, style: TextStyle(
                fontSize: 10.5,
                fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
                color: primary ? Colors.white : AppColors.text2)),
            ),
          ),
        ),
      ),
    );
  }
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


