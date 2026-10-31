import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../hash_service.dart';

class HashPage extends StatefulWidget {
  const HashPage({super.key});
  @override
  State<HashPage> createState() => _HashPageState();
}

class _HashPageState extends State<HashPage> {
  final _input = TextEditingController();
  Map<String, String> _hashes = const {};

  @override
  void dispose() { _input.dispose(); super.dispose(); }

  void _calc() => setState(() => _hashes = _input.text.isEmpty ? {} : HashService.all(_input.text));

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _header(),
      Expanded(
        child: Container(
          color: AppColors.bg,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            _inputCard(),
            const SizedBox(height: 10),
            Expanded(child: _resultCard()),
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
            child: const Icon(Icons.fingerprint, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('哈希计算', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5-7', color: AppColors.accent, background: AppColors.accentSoft),
          const Spacer(),
          const Text('MD5 · SHA-1/256/512 · UTF-8', style: AppTypography.aux),
        ]),
      );

  Widget _inputCard() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.panel, borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Expanded(
        child: SizedBox(
          height: 34,
          child: TextField(
            key: const ValueKey('hash_input'),
            controller: _input,
            onSubmitted: (_) => _calc(),
            style: const TextStyle(fontSize: 11.5),
            decoration: InputDecoration(
              hintText: '输入要计算摘要的文本', isDense: true, filled: true, fillColor: AppColors.fill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              hintStyle: const TextStyle(fontSize: 10, color: AppColors.text4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.control), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.2)),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 72, height: 34,
        child: FilledButton(
          key: const ValueKey('hash_run'),
          onPressed: _calc,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
            textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('计算')),
      ),
    ]),
  );

  Widget _resultCard() {
    final items = _hashes.entries.toList();
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
              const Text('摘要结果', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
              const Spacer(),
              if (items.isNotEmpty)
                IconButton(
                  key: const ValueKey('hash_copy_all'),
                  tooltip: '复制全部',
                  icon: const Icon(Icons.copy_all_outlined, size: 16),
                  color: AppColors.text3,
                  onPressed: () async {
                    final text = items.map((e) => '${e.key}: ${e.value}').join('\n');
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制全部摘要'), duration: Duration(seconds: 2)));
                  },
                ),
            ]),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.fingerprint, size: 26, color: AppColors.text4),
                  const SizedBox(height: 8),
                  Text('输入文本后点击「计算」', style: AppTypography.aux.copyWith(color: AppColors.text4)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderSoft),
                  itemBuilder: (_, i) {
                    final e = items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Row(children: [
                        SizedBox(
                          width: 70,
                          child: Text(e.key, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.text2))),
                        Expanded(
                          child: SelectableText(e.value,
                              style: AppTypography.code.copyWith(fontSize: 10.5))),
                        IconButton(
                          tooltip: '复制',
                          icon: const Icon(Icons.copy, size: 14),
                          color: AppColors.text3,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: e.value));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制 ${e.key}'), duration: const Duration(seconds: 2)));
                          },
                        ),
                      ]),
                    );
                  },
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


