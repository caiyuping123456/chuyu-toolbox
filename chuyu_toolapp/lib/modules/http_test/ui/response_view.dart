import 'package:flutter/material.dart';

import '../../../core/export_service.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../models.dart';
import 'json_highlight.dart';

/// 响应视图：状态色标 / 耗时 / 体积 + Body(Pretty/Raw) / Headers + 复制（SPEC §6.2）。
class ResponseView extends StatefulWidget {
  const ResponseView({super.key, required this.result, required this.sending});

  final HttpResult? result;
  final bool sending;

  @override
  State<ResponseView> createState() => _ResponseViewState();
}

class _ResponseViewState extends State<ResponseView> {
  int _tab = 0; // 0 Body / 1 Headers
  bool _pretty = true;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        child: widget.sending
            ? const _CenterHint(
                icon: Icons.hourglass_top, text: '发送中…', sub: '正在等待响应')
            : _body(),
      );
  }

  Widget _body() {
    final r = widget.result;
    if (r == null) {
      return const _CenterHint(
          icon: Icons.cloud_queue,
          text: '尚未发送请求',
          sub: '点击「发送」或按 Ctrl Enter');
    }
    if (r.hasError) {
      return _CenterHint(
        icon: Icons.error_outline,
        text: '请求失败',
        sub: '${r.error ?? ''}（${r.durationMs} ms）',
        color: AppColors.err,
      );
    }

    final prettyJson = BodyFormatter.tryPrettyJson(r.body);
    final isXml = prettyJson == null &&
        r.body.trimLeft().startsWith('<');
    final overLimit = r.sizeBytes > BodyFormatter.prettyLimitBytes;
    final effectivePretty = _pretty && !overLimit;
    final prettyText = overLimit
        ? null
        : (prettyJson ?? (isXml ? BodyFormatter.prettyXml(r.body) : null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: switch (r.statusClass) {
                    2 => AppColors.okBg,
                    3 || 4 => AppColors.warnBg,
                    _ => AppColors.errBg,
                  },
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  r.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: switch (r.statusClass) {
                      2 => AppColors.ok,
                      3 || 4 => AppColors.warn,
                      _ => AppColors.err,
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${r.durationMs} ms', style: AppTypography.aux),
              const SizedBox(width: 8),
              Text(fmtSize(r.sizeBytes), style: AppTypography.aux),
              const Spacer(),
              _ExportButton(text: r.body),
        _CopyButton(text: r.body),
              const SizedBox(width: 10),
              _TabButton('Body', _tab == 0, () => setState(() => _tab = 0)),
              const SizedBox(width: 8),
              _TabButton('Headers', _tab == 1, () => setState(() => _tab = 1)),
            ],
          ),
        ),
        const Divider(height: 12),
        Expanded(
          child: _tab == 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _TabButton('Pretty', effectivePretty,
                              overLimit ? null : () => setState(() => _pretty = true)),
                          const SizedBox(width: 8),
                          _TabButton('Raw', !effectivePretty,
                              () => setState(() => _pretty = false)),
                          const SizedBox(width: 10),
                          if (overLimit)
                            const Text('响应超过 2 MB，已禁用 Pretty',
                                style: AppTypography.aux),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: r.body.isEmpty
                            ? const Text('（响应体为空）', style: AppTypography.aux)
                            : SingleChildScrollView(
                                child: effectivePretty && prettyText != null
                                    ? SelectableText.rich(
                                        BodyFormatter.highlight(
                                            prettyText, context))
                                    : SelectableText(
                                        r.body,
                                        style: AppTypography.code
                                            .copyWith(fontSize: 11.5),
                                      ),
                              ),
                      ),
                    ),
                  ],
                )
              : _headersList(r),
        ),
      ],
    );
  }

  Widget _headersList(HttpResult r) {
    if (r.headers.isEmpty) {
      return const Center(
          child: Text('（无响应头）', style: AppTypography.aux));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: r.headers.length,
      itemBuilder: (context, i) {
        final e = r.headers.entries.elementAt(i);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: Text(e.key,
                    style: AppTypography.code.copyWith(
                        fontSize: 11, color: AppColors.text3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.value,
                    style: AppTypography.code.copyWith(fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CenterHint extends StatelessWidget {
  const _CenterHint(
      {required this.icon, required this.text, required this.sub, this.color});

  final IconData icon;
  final String text;
  final String sub;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color ?? AppColors.text4),
          const SizedBox(height: 6),
          Text(text,
              style: AppTypography.body.copyWith(
                  color: color ?? AppColors.text2,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5)),
          const SizedBox(height: 2),
          Text(sub, style: AppTypography.aux),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton(this.label, this.selected, this.onTap);

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTypography.nav.copyWith(
                    fontSize: 11.5,
                    color: selected ? AppColors.text : AppColors.text3,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400)),
            const SizedBox(height: 2),
            Container(
              height: 2,
              width: 24,
              color: selected ? AppColors.accent : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        key: const ValueKey('resp_export'),
        onTap: text.isEmpty
            ? null
            : () async {
                final r = await ExportService.exportText(
                    text, 'http-response', 'txt');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(r.ok
                        ? '已导出到 ${r.path}'
                        : r.error!),
                    duration: const Duration(seconds: 3),
                  ));
              },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.file_download_outlined,
                size: 12,
                color: text.isEmpty ? AppColors.text4 : AppColors.text3),
            const SizedBox(width: 3),
            Text('导出',
                style: TextStyle(
                    fontSize: 11,
                    color: text.isEmpty ? AppColors.text4 : AppColors.text3)),
          ]),
        ),
      ),
    );
  }
}
class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('响应体已复制'),
              duration: Duration(seconds: 2)));
      },
      borderRadius: BorderRadius.circular(6),
      hoverColor: AppColors.hover,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.copy, size: 12, color: AppColors.text3),
            SizedBox(width: 4),
            Text('复制', style: TextStyle(fontSize: 11, color: AppColors.text3)),
          ],
        ),
      ),
    );
  }
}

String fmtSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
}

