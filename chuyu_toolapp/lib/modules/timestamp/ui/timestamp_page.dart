import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../time_conv.dart';

/// 时间戳转换工作区：Unix ↔ 日期，双向 + 当前时间。
class TimestampPage extends StatefulWidget {
  const TimestampPage({super.key});

  @override
  State<TimestampPage> createState() => _TimestampPageState();
}

class _TimestampPageState extends State<TimestampPage> {
  final _unixCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String _now = TimeConverter.nowAll();

  @override
  void dispose() {
    _unixCtrl.dispose(); _dateCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  void _fromUnix() {
    final r = TimeConverter.fromUnix(_unixCtrl.text);
    setState(() => _dateCtrl.text = r.output ?? '');
    if (!r.ok) _snack(r.error!);
  }

  void _toUnix() {
    final r = TimeConverter.toUnix(_dateCtrl.text);
    setState(() => _unixCtrl.text = r.output ?? '');
    if (!r.ok) _snack(r.error!);
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
                _card('时间戳 → 日期', [
                  Row(children: [
                    Expanded(child: _field(
                      key: 'ts_unix_field',
                      ctrl: _unixCtrl,
                      hint: '秒 / 毫秒 / 微秒，自动识别',
                      onSubmitted: _fromUnix)),
                    const SizedBox(width: 8),
                    _primaryBtn('转换', key: 'ts_to_date', onTap: _fromUnix),
                  ]),
                  const SizedBox(height: 8),
                  _readOnly(_dateCtrl),
                ]),
                const SizedBox(height: 10),
                _card('日期 → 时间戳', [
                  Row(children: [
                    Expanded(child: _field(
                      key: 'ts_date_field',
                      ctrl: TextEditingController(text: _dateCtrl.text),
                      hint: '2026-10-31 14:30 或 ISO 8601',
                      onSubmitted: _toUnix,
                      onChanged: (v) {})),
                    const SizedBox(width: 8),
                    _primaryBtn('转换', key: 'ts_to_unix', onTap: _toUnix),
                  ]),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_now, style: AppTypography.code.copyWith(fontSize: 10.5))),
                    _primaryBtn('刷新', key: 'ts_refresh', onTap: () => setState(() => _now = TimeConverter.nowAll())),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
            child: const Icon(Icons.schedule, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('时间戳转换', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5-5', color: AppColors.accent, background: AppColors.accentSoft),
          const Spacer(),
          const Text('本地时区 · 自动识别精度', style: AppTypography.aux),
        ]),
      );

  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.panel, borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
      const SizedBox(height: 8),
      ...children,
    ]),
  );

  Widget _field({String? key, required TextEditingController ctrl, required String hint,
      required VoidCallback onSubmitted, ValueChanged<String>? onChanged}) {
    return SizedBox(
      height: 34,
      child: TextField(
        key: key == null ? null : ValueKey(key),
        controller: ctrl,
        onSubmitted: (_) => onSubmitted(),
        onChanged: onChanged,
        style: AppTypography.code.copyWith(fontSize: 11),
        decoration: InputDecoration(
          hintText: hint, isDense: true, filled: true, fillColor: AppColors.fill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          hintStyle: const TextStyle(fontSize: 10, color: AppColors.text4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.control), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.2)),
        ),
      ),
    );
  }

  Widget _readOnly(TextEditingController ctrl) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 34),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadius.control)),
    child: SelectableText(
      ctrl.text.isEmpty ? '结果' : ctrl.text,
      style: AppTypography.code.copyWith(
        fontSize: 10.5, color: ctrl.text.isEmpty ? AppColors.text4 : AppColors.text)),
  );

  Widget _primaryBtn(String label, {String? key, required VoidCallback onTap}) => SizedBox(
    width: 72, height: 34,
    child: FilledButton(
      key: key == null ? null : ValueKey(key),
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent, foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      child: Text(label)),
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

