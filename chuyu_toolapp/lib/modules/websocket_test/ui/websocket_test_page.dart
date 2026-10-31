import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../ws_client.dart';

/// WebSocket 测试工作区（M5-1）。
/// 连接卡 + 消息记录 + 发送区；文本收发；Ctrl Enter 发送。
class WebSocketTestPage extends StatefulWidget {
  const WebSocketTestPage({super.key, this.connector});

  /// 测试注入；生产为 dart:io WebSocket。
  final WsConnector? connector;

  @override
  State<WebSocketTestPage> createState() => _WebSocketTestPageState();
}

class _WebSocketTestPageState extends State<WebSocketTestPage> {
  late final WsController _c;
  final TextEditingController _url =
      TextEditingController(text: 'ws://localhost:8080/ws');
  final TextEditingController _message = TextEditingController();
  final FocusNode _messageFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _c = WsController(connector: widget.connector);
    _c.addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    _url.dispose();
    _message.dispose();
    _messageFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_c.isConnected) {
      await _c.disconnect();
      return;
    }
    if (_c.isBusy) return;
    await _c.connect(_url.text);
    if (mounted && _c.isConnected) _messageFocus.requestFocus();
  }

  void _send() {
    final text = _message.text;
    if (text.trim().isEmpty) return;
    if (!_c.isConnected) {
      _c.send(text);
      return;
    }
    _c.send(text);
    _message.clear();
    _messageFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _send,
      },
      child: Column(
        children: [
          _header(),
          Expanded(
            child: Container(
              color: AppColors.bg,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _connectionCard(),
                  const SizedBox(height: 10),
                  Expanded(child: _logCard()),
                  const SizedBox(height: 10),
                  _composer(),
                ],
              ),
            ),
          ),
        ],
      ),
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
            child: const Icon(Icons.settings_input_antenna,
                size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 9),
          const Text('WebSocket 测试',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(width: 8),
          const _Pill('模块 v1.0 · M5',
              color: AppColors.accent, background: AppColors.accentSoft),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('长连接收发调试 · 仅文本 · 本地直连',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.aux),
          ),
          Text('${_c.log.length} 条消息', style: AppTypography.aux),
        ],
      ),
    );
  }

  Widget _connectionCard() {
    final connected = _c.isConnected;
    final busy = _c.isBusy;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration,
      child: Row(
        children: [
          _StatusPill(status: _c.status),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 34,
              child: TextField(
                key: const ValueKey('ws_url_field'),
                controller: _url,
                enabled: !connected && !busy,
                onSubmitted: (_) => _toggle(),
                style: AppTypography.code.copyWith(fontSize: 10.5, height: 1.3),
                decoration: _inputDecoration(
                    hint: 'ws://localhost:8080/ws', prefix: Icons.link),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _connectButton(connected: connected, busy: busy),
        ],
      ),
    );
  }

  Widget _connectButton({required bool connected, required bool busy}) {
    if (connected) {
      return SizedBox(
        width: 76,
        height: 34,
        child: OutlinedButton(
          key: const ValueKey('ws_connect'),
          onPressed: () => _toggle(),
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
          child: const Text('断开'),
        ),
      );
    }
    return SizedBox(
      width: 76,
      height: 34,
      child: FilledButton(
        key: const ValueKey('ws_connect'),
        onPressed: busy ? null : () => _toggle(),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accentSoft,
          disabledForegroundColor: AppColors.accent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control)),
          textStyle:
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(busy ? '连接中…' : '连接'),
      ),
    );
  }

  Widget _logCard() {
    final entries = _c.log;
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
                  const Text('消息记录',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2)),
                  const SizedBox(width: 6),
                  _Pill('${entries.length} 条'),
                  const Spacer(),
                  const Text('文本 · Ctrl Enter 发送', style: AppTypography.aux),
                  const SizedBox(width: 6),
                  IconButton(
                    key: const ValueKey('ws_clear'),
                    onPressed: entries.isEmpty ? null : _c.clear,
                    tooltip: '清空消息',
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
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.forum_outlined,
                            size: 28, color: AppColors.text4),
                        const SizedBox(height: 8),
                        Text('连接后开始收发消息',
                            style: AppTypography.aux
                                .copyWith(color: AppColors.text4)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _logTile(entries[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _logTile(WsLogEntry e) {
    if (e.direction == WsDirection.system) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            e.text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 9.5,
                height: 1.5,
                color: e.error ? AppColors.err : AppColors.text4),
          ),
        ),
      );
    }
    final sent = e.direction == WsDirection.sent;
    return Align(
      alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            sent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: sent ? AppColors.accentSoft : AppColors.fill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      sent ? AppColors.accentBorder : AppColors.borderSoft),
            ),
            child: Text(
              e.text,
              style: AppTypography.code.copyWith(fontSize: 10.5, height: 1.55),
            ),
          ),
          const SizedBox(height: 3),
          Text('${sent ? '已发送' : '已接收'} · ${e.timeLabel}',
              style: const TextStyle(fontSize: 8.5, color: AppColors.text4)),
        ],
      ),
    );
  }

  Widget _composer() {
    final can = _c.isConnected;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 34,
              child: TextField(
                key: const ValueKey('ws_message_field'),
                controller: _message,
                focusNode: _messageFocus,
                onSubmitted: (_) => _send(),
                style: const TextStyle(fontSize: 11.5),
                decoration: _inputDecoration(
                    hint: can ? '输入要发送的文本…' : '连接后即可发送消息'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            height: 34,
            child: FilledButton(
              key: const ValueKey('ws_send'),
              onPressed: can ? _send : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.fill,
                disabledForegroundColor: AppColors.text4,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control)),
                textStyle: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('发送'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? prefix}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AppColors.fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      hintStyle: const TextStyle(fontSize: 10.5, color: AppColors.text4),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final WsStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      WsStatus.idle => ('未连接', AppColors.text3, AppColors.fill),
      WsStatus.connecting => ('连接中…', AppColors.warn, AppColors.warnBg),
      WsStatus.connected => ('已连接', AppColors.ok, AppColors.okBg),
      WsStatus.closed => ('已断开', AppColors.text3, AppColors.fill),
      WsStatus.error => ('连接失败', AppColors.err, AppColors.errBg),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 9.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}




