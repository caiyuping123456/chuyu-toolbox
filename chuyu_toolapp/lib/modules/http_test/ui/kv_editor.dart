import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../models.dart';

/// KV 可编辑表格：Params / Headers / 表单类 Body 共用（SPEC §6.1）。
/// 直接原地修改 [entries]，任何变更通过 [onChanged] 通知父级刷新。
class KvEditor extends StatelessWidget {
  const KvEditor({
    super.key,
    required this.entries,
    required this.onChanged,
    this.keyHint = 'KEY',
    this.valueHint = 'VALUE',
  });

  final List<KvEntry> entries;
  final VoidCallback onChanged;
  final String keyHint;
  final String valueHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 22),
            const Expanded(flex: 10, child: Text('KEY', style: AppTypography.aux)),
            const SizedBox(width: 8),
            const Expanded(flex: 12, child: Text('VALUE', style: AppTypography.aux)),
            const SizedBox(width: 8),
            const Expanded(flex: 9, child: Text('描述', style: AppTypography.aux)),
            const SizedBox(width: 8),
            const SizedBox(width: 24),
          ],
        ),
        for (final e in entries)
          _KvRow(
            entry: e,
            key: ValueKey(e.id),
            keyHint: keyHint,
            valueHint: valueHint,
            onChanged: onChanged,
            onDelete: () {
              entries.removeWhere((x) => x.id == e.id);
              onChanged();
            },
          ),
        InkWell(
          onTap: () {
            entries.add(KvEntry());
            onChanged();
          },
          borderRadius: BorderRadius.circular(6),
          hoverColor: AppColors.hover,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.add, size: 13, color: AppColors.text3),
                const SizedBox(width: 6),
                Text('新增一行', style: AppTypography.aux),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KvRow extends StatefulWidget {
  const _KvRow({
    required super.key,
    required this.entry,
    required this.onChanged,
    required this.onDelete,
    required this.keyHint,
    required this.valueHint,
  });

  final KvEntry entry;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final String keyHint;
  final String valueHint;

  @override
  State<_KvRow> createState() => _KvRowState();
}

class _KvRowState extends State<_KvRow> {
  late final TextEditingController _key;
  late final TextEditingController _value;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _key = TextEditingController(text: widget.entry.key)..addListener(_syncKey);
    _value = TextEditingController(text: widget.entry.value)
      ..addListener(_syncValue);
    _note = TextEditingController(text: widget.entry.note)
      ..addListener(_syncNote);
  }

  void _syncKey() => widget.entry.key = _key.text;
  void _syncValue() => widget.entry.value = _value.text;
  void _syncNote() => widget.entry.note = _note.text;

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Checkbox(
              value: widget.entry.enabled,
              onChanged: (v) {
                setState(() => widget.entry.enabled = v ?? true);
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 10,
            child: _field(_key, widget.keyHint),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 12, child: _field(_value, widget.valueHint)),
          const SizedBox(width: 8),
          Expanded(
            flex: 9,
            child: _field(_note, '备注（可选）', muted: true),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.close, size: 12),
              color: AppColors.text4,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: '删除此行',
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool muted = false}) {
    return SizedBox(
      height: 28,
      child: TextField(
        controller: c,
        style: AppTypography.code.copyWith(fontSize: 11, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: AppColors.fill,
          hintStyle: TextStyle(fontSize: 10.5, color: AppColors.text4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
          ),
        ),
      ),
    );
  }
}
