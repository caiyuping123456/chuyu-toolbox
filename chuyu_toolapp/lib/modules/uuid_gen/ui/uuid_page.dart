import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/export_service.dart';
import '../../../core/theme.dart';
import '../uuid_service.dart';

class UuidPage extends StatefulWidget {
  const UuidPage({super.key});
  @override
  State<UuidPage> createState() => _UuidPageState();
}

class _UuidPageState extends State<UuidPage> {
  int _count = 5;
  bool _uppercase = false;
  bool _noDash = false;
  List<String> _ids = const <String>[];

  void _gen() => setState(() {
        _ids = UuidService.generate(_count);
        if (_noDash) _ids = [for (final id in _ids) id.replaceAll('-', '')];
        if (_uppercase) _ids = [for (final id in _ids) id.toUpperCase()];
      });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _header(),
      Expanded(
        child: Container(
          color: AppColors.bg,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _optCard(),
            const SizedBox(height: 10),
            Expanded(child: _listCard()),
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
            child: const Icon(Icons.vpn_key_outlined, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('UUID 生成', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5-8', color: AppColors.accent, background: AppColors.accentSoft),
          const Spacer(),
          const Text('UUID v4 · CSPRNG', style: AppTypography.aux),
        ]),
      );

  Widget _optCard() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.panel, borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: AppColors.border)),
    child: Row(children: [
      const Text('数量', style: TextStyle(fontSize: 10.5, color: AppColors.text2)),
      const SizedBox(width: 8),
      Container(
        width: 64, height: 30,
        decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadius.control)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            key: const ValueKey('uuid_count'),
            value: _count,
            isDense: true, isExpanded: true,
            icon: const Icon(Icons.expand_more, size: 14, color: AppColors.text3),
            style: const TextStyle(fontSize: 10, color: AppColors.text2),
            items: const [1, 5, 10, 20, 50, 100].map((n) => DropdownMenuItem(value: n, child: Padding(padding: EdgeInsets.only(left: 8), child: Text('$n 个')))).toList(),
            onChanged: (v) => setState(() => _count = v ?? 5),
          ),
        ),
      ),
      const SizedBox(width: 10),
      _chip('大写', _uppercase, (v) => setState(() => _uppercase = v)),
      const SizedBox(width: 6),
      _chip('无连字符', _noDash, (v) => setState(() => _noDash = v)),
      const Spacer(),
      SizedBox(
        width: 84, height: 32,
        child: FilledButton(
          key: const ValueKey('uuid_generate'),
          onPressed: _gen,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
            textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('生成')),
      ),
      const SizedBox(width: 6),

      SizedBox(
        width: 84, height: 32,
        child: OutlinedButton(
          key: const ValueKey('uuid_export'),
          onPressed: _ids.isEmpty ? null : () async {
            final r = await ExportService.exportText(
                _ids.join('\n'), 'uuid-list', 'txt');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(r.ok ? '已导出到 ${r.path}' : r.error!),
                duration: const Duration(seconds: 3)));
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text2, side: const BorderSide(color: AppColors.border), padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
            textStyle: const TextStyle(fontSize: 11.5), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('导出')),
      ),
      const SizedBox(width: 6),
      SizedBox(
        width: 84, height: 32,
        child: OutlinedButton(
          onPressed: _ids.isEmpty ? null : () async {
            await Clipboard.setData(ClipboardData(text: _ids.join('\n')));
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制全部'), duration: Duration(seconds: 2)));
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text2, side: const BorderSide(color: AppColors.border), padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
            textStyle: const TextStyle(fontSize: 11.5), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('复制全部')),
      ),
    ]),
  );

  Widget _chip(String label, bool value, ValueChanged<bool> on) => SizedBox(
    height: 26,
    child: Material(
      color: value ? AppColors.accentSoft : AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: value ? AppColors.accentBorder : AppColors.border)),
      child: InkWell(
        onTap: () => on(!value),
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(child: Text(label, style: TextStyle(fontSize: 9.5,
              color: value ? AppColors.accentDark : AppColors.text3,
              fontWeight: value ? FontWeight.w600 : FontWeight.w400)))))));

  Widget _listCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel, borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border)),
      child: Column(children: [
        SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const Text('生成结果', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
              const SizedBox(width: 6),
              Text('${_ids.length} 个', style: AppTypography.aux),
            ]),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _ids.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.vpn_key_outlined, size: 26, color: AppColors.text4),
                  const SizedBox(height: 8),
                  Text('选择数量后点击「生成」', style: AppTypography.aux.copyWith(color: AppColors.text4)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _ids.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderSoft),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: Row(children: [
                      SizedBox(width: 30, child: Text('#${i + 1}', style: const TextStyle(fontSize: 9.5, color: AppColors.text4))),
                      Expanded(child: SelectableText(_ids[i], style: AppTypography.code.copyWith(fontSize: 10.5))),
                      IconButton(
                        tooltip: '复制',
                        icon: const Icon(Icons.copy, size: 14), color: AppColors.text3,
                        padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: _ids[i]));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制 #${i + 1}'), duration: const Duration(seconds: 2)));
                        },
                      ),
                    ]),
                  ),
                ),
        ),
      ]),
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



