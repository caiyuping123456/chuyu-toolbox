import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../models.dart';
import 'kv_editor.dart';

/// Body 编辑器：none / form-data / x-www-form-urlencoded / raw（JSON·text·XML·HTML）。
class BodyEditor extends StatelessWidget {
  const BodyEditor({
    super.key,
    required this.body,
    required this.rawController,
    required this.onChanged,
  });

  final HttpBodySpec body;
  final TextEditingController rawController;
  final VoidCallback onChanged;

  static const _kindLabels = <BodyKind, String>{
    BodyKind.none: 'none',
    BodyKind.formData: 'form-data',
    BodyKind.urlEncoded: 'x-www-form-urlencoded',
    BodyKind.raw: 'raw',
  };

  static const _rawLabels = <RawType, String>{
    RawType.json: 'JSON',
    RawType.text: 'Text',
    RawType.xml: 'XML',
    RawType.html: 'HTML',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final e in _kindLabels.entries) _chip(e.value, e.key == body.kind, () {
              body.kind = e.key;
              onChanged();
            }),
          ],
        ),
        const SizedBox(height: 8),
        switch (body.kind) {
          BodyKind.none => const Text('当前请求不携带 Body。', style: AppTypography.aux),
          BodyKind.raw => _raw(),
          BodyKind.formData => _form('字段名', '值'),
          BodyKind.urlEncoded => _form('字段名', '值'),
        },
      ],
    );
  }

  Widget _raw() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: [
            for (final e in _rawLabels.entries)
              _chip(e.value, e.key == body.rawType, () {
                body.rawType = e.key;
                onChanged();
              }, small: true),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: rawController,
          onChanged: (t) {
            body.rawContent = t;
            onChanged();
          },
          keyboardType: TextInputType.multiline,
          maxLines: null,
          minLines: 5,
          style: AppTypography.code.copyWith(fontSize: 11),
          decoration: InputDecoration(
            hintText: '输入 ${_rawLabels[body.rawType]} 内容…',
            filled: true,
            fillColor: AppColors.fill,
            hintStyle: TextStyle(fontSize: 10.5, color: AppColors.text4),
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form(String kh, String vh) {
    return KvEditor(
      entries: body.formEntries,
      onChanged: onChanged,
      keyHint: kh,
      valueHint: vh,
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {bool small = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 9 : 10, vertical: small ? 3 : 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTypography.nav.copyWith(
            fontSize: small ? 10.5 : 11.5,
            color: selected ? AppColors.text : AppColors.text3,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
