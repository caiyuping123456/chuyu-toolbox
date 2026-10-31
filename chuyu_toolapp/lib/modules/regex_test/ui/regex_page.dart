import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../regex_engine.dart';

class RegexPage extends StatefulWidget {
  const RegexPage({super.key});
  @override
  State<RegexPage> createState() => _RegexPageState();
}

class _RegexPageState extends State<RegexPage> {
  final _pattern = TextEditingController(text: r'\w+@\w+\.\w+');
  final _input = TextEditingController(
      text: '联系 a@b.com 或 c.d@e.org，无效：x@y');
  final _replacement = TextEditingController();
  RegexResult? _r;
  bool _global = true, _multi = false, _case = true;
  int _tab = 0; // 0 匹配 1 替换预览

  @override
  void dispose() {
    _pattern.dispose(); _input.dispose(); _replacement.dispose();
    super.dispose();
  }

  void _run() => setState(() {
        _r = RegexEngine.run(_pattern.text, _input.text,
            global: _global, multiline: _multi, caseSensitive: _case);
      });

  String? _preview() {
    if (_r == null || !_r!.ok) return null;
    if (_replacement.text.isEmpty) return null;
    try {
      final re = RegExp(_pattern.text,
          multiLine: _multi, caseSensitive: _case);
      return _input.text.replaceAllMapped(re, (m) {
        var out = _replacement.text;
        for (var i = 0; i <= m.groupCount; i++) {
          out = out.replaceAll('\$$i', m.group(i) ?? '');
        }
        return out;
      });
    } catch (e) {
      return null;
    }
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
            _exprCard(),
            const SizedBox(height: 10),
            Expanded(child: _ioCard()),
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
            child: const Icon(Icons.rule, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('正则测试', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5-6', color: AppColors.accent, background: AppColors.accentSoft),
          const Spacer(),
          if (_r != null && _r!.ok)
            Text('${_r!.matches.length} 个匹配', style: AppTypography.aux),
        ]),
      );

  Widget _exprCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration,
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadius.control)),
            child: const Text('/', style: AppTypography.code),
          ),
          const SizedBox(width: 1),
          Expanded(child: _field(key: 're_pattern', ctrl: _pattern, hint: r'正则表达式，如 \w+@\w+\.\w+', onSubmitted: _run)),
          const SizedBox(width: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadius.control)),
            child: Text('/${_global ? 'g' : ''}${_multi ? 'm' : ''}${_case ? '' : 'i'}',
                style: AppTypography.code),
          ),
          const SizedBox(width: 8),
          _primaryBtn('匹配', key: 're_run', onTap: _run),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _flag('全局', _global, (v) => setState(() => _global = v)),
          const SizedBox(width: 6),
          _flag('多行', _multi, (v) => setState(() => _multi = v)),
          const SizedBox(width: 6),
          _flag('区分大小写', _case, (v) => setState(() => _case = v)),
        ]),
      ]),
    );
  }

  Widget _flag(String label, bool value, ValueChanged<bool> on) => SizedBox(
    height: 24,
    child: Material(
      color: value ? AppColors.accentSoft : AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(color: value ? AppColors.accentBorder : AppColors.border)),
      child: InkWell(
        onTap: () => on(!value),
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: 9.5,
                color: value ? AppColors.accentDark : AppColors.text3,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
      ),
    ),
  );

  Widget _ioCard() {
    final r = _r;
    final preview = _preview();
    return Container(
      decoration: _cardDecoration,
      child: Column(children: [
        SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              for (var i = 0; i < 2; i++)
                GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                        color: _tab == i ? AppColors.accent : Colors.transparent, width: 2))),
                    alignment: Alignment.center,
                    child: Text(i == 0 ? '匹配结果' : '替换预览',
                        style: TextStyle(fontSize: 11, fontWeight: _tab == i ? FontWeight.w600 : FontWeight.w400,
                            color: _tab == i ? AppColors.text : AppColors.text3)),
                  ),
                ),
            ]),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _tab == 0
              ? Column(children: [
                  _srcHead(),
                  const Divider(height: 1),
                  Expanded(
                    child: r == null
                        ? _empty('输入正则后点击「匹配」')
                        : !r.ok
                            ? _err(r.error!)
                            : r.matches.isEmpty
                                ? _empty('无匹配')
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    itemCount: r.matches.length,
                                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderSoft),
                                    itemBuilder: (_, i) {
                                      final m = r.matches[i];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        child: Row(children: [
                                          SizedBox(width: 28, child: Text('#${i + 1}', style: const TextStyle(fontSize: 9.5, color: AppColors.text4))),
                                          Expanded(
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text(m.text, style: AppTypography.code.copyWith(fontSize: 10.5)),
                                              if (m.groups.any((g) => g != null))
                                                Text('组：${m.groups.map((g) => g ?? '—').join(' | ')}',
                                                    style: const TextStyle(fontSize: 9, color: AppColors.text4)),
                                            ]),
                                          ),
                                          Text('${m.start}-${m.end}', style: const TextStyle(fontSize: 9, color: AppColors.text4)),
                                        ]),
                                      );
                                    },
                                  ),
                  ),
                ])
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: _field(key: 're_replacement', ctrl: _replacement, hint: r'替换文本，用 $1 $2 引用分组', onSubmitted: () {}),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: preview == null
                        ? _empty('输入替换文本后显示预览')
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(preview, style: AppTypography.code.copyWith(fontSize: 11))),
                  ),
                ]),
        ),
      ]),
    );
  }

  Widget _srcHead() => SizedBox(
    height: 30,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(alignment: Alignment.centerLeft,
        child: Text('测试文本', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3))),
    ),
  );

  Widget _empty(String t) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.search_off, size: 26, color: AppColors.text4),
    const SizedBox(height: 8),
    Text(t, style: AppTypography.aux.copyWith(color: AppColors.text4)),
  ]));

  Widget _err(String msg) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      const Icon(Icons.error_outline, size: 14, color: AppColors.err),
      const SizedBox(width: 6),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 10, color: AppColors.err))),
    ]),
  );

  Widget _field({String? key, required TextEditingController ctrl, required String hint, required VoidCallback onSubmitted}) {
    return SizedBox(
      height: 34,
      child: TextField(
        key: key == null ? null : ValueKey(key),
        controller: ctrl,
        onSubmitted: (_) => onSubmitted(),
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


