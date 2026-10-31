import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../port_scanner.dart';

/// 端口连通检测工作区（M5-2）。
/// 主机 + 端口列表/范围 → 并发 TCP 探测；结果表、进度、统计、停止/清空。
class PortScanPage extends StatefulWidget {
  const PortScanPage({super.key, this.probe});

  /// 测试注入；生产为 dart:io Socket。
  final PortProbe? probe;

  @override
  State<PortScanPage> createState() => _PortScanPageState();
}

class _PortScanPageState extends State<PortScanPage> {
  late final PortScanController _c;
  final TextEditingController _host =
      TextEditingController(text: '127.0.0.1');
  final TextEditingController _ports =
      TextEditingController(text: '80,443,8000-8010');
  int _timeoutMs = 800;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _c = PortScanController(probe: widget.probe);
    _c.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    _host.dispose();
    _ports.dispose();
    super.dispose();
  }

  Future<void> _scanOrStop() async {
    if (_c.isRunning) {
      _c.stop();
      return;
    }
    final host = PortParser.normalizeHost(_host.text);
    if (host == null) {
      setState(() => _parseError = '请输入有效的主机名或 IP');
      return;
    }
    final parsed = PortParser.parse(_ports.text);
    if (!parsed.ok) {
      setState(() => _parseError = parsed.errors.first);
      return;
    }
    setState(() => _parseError = null);
    await _c.scan(
        host: host, ports: parsed.ports, timeoutMs: _timeoutMs);
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
                _targetCard(),
                const SizedBox(height: 10),
                Expanded(child: _resultsCard()),
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
            child: const Icon(Icons.network_check,
                size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('端口连通检测',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5-2',
              color: AppColors.accent, background: AppColors.accentSoft),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('TCP 连接探测 · 本地直连 · 不发送数据',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.aux),
          ),
          Text('${_c.total} 个端口', style: AppTypography.aux),
        ],
      ),
    );
  }

  Widget _targetCard() {
    final running = _c.isRunning;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 170,
                height: 34,
                child: TextField(
                  key: const ValueKey('port_host_field'),
                  controller: _host,
                  enabled: !running,
                  onSubmitted: (_) => _scanOrStop(),
                  style: AppTypography.code.copyWith(fontSize: 10.5),
                  decoration: _decoration(
                      hint: '主机 / IP', prefix: Icons.dns_outlined),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    key: const ValueKey('port_ports_field'),
                    controller: _ports,
                    enabled: !running,
                    onSubmitted: (_) => _scanOrStop(),
                    style: AppTypography.code.copyWith(fontSize: 10.5),
                    decoration: _decoration(
                        hint: '端口：80,443,8000-8010',
                        prefix: Icons.tag),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _timeoutField(),
              const SizedBox(width: 8),
              _scanButton(running: running),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  _parseError ??
                      '支持逗号 / 空格 / 范围（如 8000-8010），最多 ${PortParser.maxPorts} 个端口',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 9.5,
                      color: _parseError == null
                          ? AppColors.text4
                          : AppColors.err),
                ),
              ),
              if (_c.total > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${_c.scanned} / ${_c.total}',
                    style: AppTypography.aux,
                  ),
                ),
            ],
          ),
          if (_c.total > 0) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Container(color: AppColors.fill),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _c.progress.clamp(0.0, 1.0).toDouble(),
                      child: Container(color: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeoutField() {
    return Container(
      width: 94,
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          key: const ValueKey('port_timeout'),
          value: _timeoutMs,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.expand_more,
              size: 14, color: AppColors.text3),
          style: const TextStyle(fontSize: 10, color: AppColors.text2),
          items: const [
            DropdownMenuItem(value: 300, child: Text('300 ms')),
            DropdownMenuItem(value: 800, child: Text('800 ms')),
            DropdownMenuItem(value: 1500, child: Text('1500 ms')),
            DropdownMenuItem(value: 3000, child: Text('3000 ms')),
          ],
          onChanged: _c.isRunning
              ? null
              : (v) => setState(() => _timeoutMs = v ?? 800),
        ),
      ),
    );
  }

  Widget _scanButton({required bool running}) {
    if (running) {
      return SizedBox(
        width: 92,
        height: 34,
        child: OutlinedButton(
          key: const ValueKey('port_scan_button'),
          onPressed: _c.isStopping ? null : () => _scanOrStop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.err,
            side: const BorderSide(color: AppColors.errBg),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control)),
            textStyle:
                const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(_c.isStopping ? '停止中…' : '停止'),
        ),
      );
    }
    return SizedBox(
      width: 92,
      height: 34,
      child: FilledButton(
        key: const ValueKey('port_scan_button'),
        onPressed: () => _scanOrStop(),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle:
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('开始扫描'),
      ),
    );
  }

  Widget _resultsCard() {
    final rows = List<PortResult>.from(_c.results)
      ..sort((a, b) => a.port.compareTo(b.port));
    final statusText = switch (_c.status) {
      ScanStatus.idle => '待扫描',
      ScanStatus.running => _c.isStopping ? '停止中…' : '扫描中…',
      ScanStatus.done => '完成',
      ScanStatus.stopped => '已停止',
    };

    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Text('扫描结果',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2)),
                  const SizedBox(width: 6),
                  _Pill('开放 ${_c.openCount}',
                      color: AppColors.ok, background: AppColors.okBg),
                  const SizedBox(width: 4),
                  _Pill('关闭 ${_c.closedCount}'),
                  if (_c.problemCount > 0) ...[
                    const SizedBox(width: 4),
                    _Pill('异常 ${_c.problemCount}',
                        color: AppColors.warn, background: AppColors.warnBg),
                  ],
                  const Spacer(),
                  Text(statusText, style: AppTypography.aux),
                  const SizedBox(width: 6),
                  IconButton(
                    key: const ValueKey('port_clear'),
                    onPressed: _c.results.isEmpty || _c.isRunning
                        ? null
                        : _c.clear,
                    tooltip: '清空结果',
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    color: AppColors.text3,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 24,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const SizedBox(
                      width: 60, child: Text('端口', style: _headStyle)),
                  const SizedBox(
                      width: 90, child: Text('服务', style: _headStyle)),
                  const Text('状态', style: _headStyle),
                  const Spacer(),
                  const Text('耗时', style: _headStyle),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lan_outlined,
                            size: 28, color: AppColors.text4),
                        const SizedBox(height: 8),
                        Text('输入主机与端口后开始扫描',
                            style: AppTypography.aux
                                .copyWith(color: AppColors.text4)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.borderSoft),
                    itemBuilder: (_, i) => _resultRow(rows[i]),
                  ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headStyle =
      TextStyle(fontSize: 9, color: AppColors.text4, letterSpacing: 0.4);

  Widget _resultRow(PortResult r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 30,
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text('${r.port}',
                  style: AppTypography.code.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
            ),
            SizedBox(
              width: 90,
              child: Text(
                serviceForPort(r.port).isEmpty
                    ? '—'
                    : serviceForPort(r.port),
                style: const TextStyle(fontSize: 9.5, color: AppColors.text3),
              ),
            ),
            _Pill(
              r.stateLabel,
              color: switch (r.state) {
                PortState.open => AppColors.ok,
                PortState.closed => AppColors.text3,
                PortState.timeout => AppColors.warn,
                PortState.error => AppColors.err,
              },
              background: switch (r.state) {
                PortState.open => AppColors.okBg,
                PortState.closed => AppColors.fill,
                PortState.timeout => AppColors.warnBg,
                PortState.error => AppColors.errBg,
              },
            ),
            const Spacer(),
            Text(
              r.state == PortState.open && r.latencyMs > 0
                  ? '${r.latencyMs} ms'
                  : '—',
              style: AppTypography.code
                  .copyWith(fontSize: 9.5, color: AppColors.text3),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration({required String hint, IconData? prefix}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AppColors.fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      hintStyle: const TextStyle(fontSize: 10, color: AppColors.text4),
      prefixIcon: prefix == null
          ? null
          : Icon(prefix, size: 14, color: AppColors.text3),
      prefixIconConstraints: prefix == null
          ? null
          : const BoxConstraints(minWidth: 28, minHeight: 28),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
      ),
    );
  }
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

