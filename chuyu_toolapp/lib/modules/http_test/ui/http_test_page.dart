import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../shell/widgets.dart';
import '../http_client.dart';
import '../http_test_module.dart';
import '../models.dart';
import '../store.dart';
import 'body_editor.dart';
import 'kv_editor.dart';
import 'response_view.dart';

/// HTTP 模块工作区（SPEC §4.3 / §6）。
/// M3：集合（保存/载入重放/增删改）+ 历史（自动记录/回填/清空）+ 侧栏本地过滤。
class HttpTestPage extends StatefulWidget {
  const HttpTestPage({super.key, this.intent, this.sender, this.store});

  final HttpOpenIntent? intent;
  final HttpSender? sender; // 测试注入用
  final HttpStore? store; // 测试注入用（默认 %APPDATA%\chuyu-toolbox\…）

  @override
  State<HttpTestPage> createState() => _HttpTestPageState();
}

class _HttpTestPageState extends State<HttpTestPage> {
  static const List<String> _methods = [
    'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS',
  ];

  HttpSideTab _sideTab = HttpSideTab.collections;
  int _reqTab = 0; // Params / Headers / Body / Auth
  String _method = 'GET';

  late final TextEditingController _urlController;
  final FocusNode _urlFocus = FocusNode();
  String _paramsBase = 'https://api.example.com/users';

  final List<KvEntry> _params = <KvEntry>[
    KvEntry(key: 'page', value: '1', note: '页码'),
    KvEntry(key: 'size', value: '10', note: '每页数量'),
  ];
  final List<KvEntry> _headers = <KvEntry>[
    KvEntry(key: 'Accept', value: 'application/json'),
  ];
  final HttpBodySpec _body = HttpBodySpec();
  late final TextEditingController _rawController;

  AuthKind _authKind = AuthKind.none;
  final TextEditingController _bearerController = TextEditingController();

  int _timeoutMs = 30000;
  bool _followRedirects = true;

  HttpResult? _result;
  bool _sending = false;
  double _reqFlex = 5; // 请求卡 / 响应区高度比例（M5 增强：拖拽分栏）
  bool _syncingUrl = false;

  // 存储（M3）
  late final HttpStore _store;
  late final bool _ownsStore;
  bool _storeLoaded = false;
  late final Future<void> _storeReady;
  final Set<String> _expanded = <String>{};
  String _sideQuery = '';
  final TextEditingController _sideQueryCtrl = TextEditingController();
  String? _editingId; // 当前载入/上次保存的请求 id（保存时更新而非新增）
  String? _lastSavedName;

  @override
  void initState() {
    super.initState();
    final (base, params) =
        UrlQuery.parse('https://api.example.com/users?page=1&size=10');
    _paramsBase = base;
    _params
      ..clear()
      ..addAll(params);
    _urlController =
        TextEditingController(text: UrlQuery.build(_paramsBase, _params));
    _rawController = TextEditingController();

    _ownsStore = widget.store == null;
    _store = widget.store ?? HttpStore();
    _store.addListener(_onStoreChanged);
    _storeReady = _initStore();

    _applyIntent(widget.intent);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initStore() async {
    await _store.load();
    if (!mounted) return;
    if (_store.collections.isEmpty) {
      _store.createCollection('默认集合');
    }
    _expanded.add(_store.collections.first.id);
    setState(() => _storeLoaded = true);
  }

  @override
  void didUpdateWidget(covariant HttpTestPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.intent != null &&
        !identical(widget.intent, oldWidget.intent)) {
      _applyIntent(widget.intent);
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    if (_ownsStore) _store.dispose();
    _urlController.dispose();
    _urlFocus.dispose();
    _rawController.dispose();
    _bearerController.dispose();
    _sideQueryCtrl.dispose();
    super.dispose();
  }

  void _applyIntent(HttpOpenIntent? intent) {
    if (intent == null) return;
    if (intent.tab != null) _sideTab = intent.tab!;
    if (intent.focusUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _urlFocus.requestFocus();
      });
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  // ── URL ↔ Params 双向同步 ───────────────────────────────

  void _onUrlChanged(String text) {
    if (_syncingUrl) {
      _syncingUrl = false;
      return;
    }
    final (base, params) = UrlQuery.parse(text);
    setState(() {
      _paramsBase = base;
      _params
        ..clear()
        ..addAll(params);
    });
  }

  void _onParamsChanged() {
    final t = UrlQuery.build(_paramsBase, _params);
    if (t != _urlController.text) {
      _syncingUrl = true;
      _urlController.text = t;
    }
    setState(() {});
  }

  // ── 快照 / 载入 ─────────────────────────────────────────

  String _autoName() {
    final uri = Uri.tryParse(_urlController.text);
    return '$_method ${uri?.host ?? _urlController.text}';
  }

  KvEntry _copyKv(KvEntry e) => KvEntry(
      id: e.id, enabled: e.enabled, key: e.key, value: e.value, note: e.note);

  SavedRequest _snapshot(String name) => SavedRequest(
        id: _editingId,
        name: name,
        method: _method,
        url: _urlController.text.trim(),
        params: [for (final e in _params) _copyKv(e)],
        headers: [for (final e in _headers) _copyKv(e)],
        body: HttpBodySpec(
          kind: _body.kind,
          rawType: _body.rawType,
          rawContent: _body.rawContent,
          formEntries: [for (final e in _body.formEntries) _copyKv(e)],
        ),
        timeoutMs: _timeoutMs,
        authKind: _authKind,
        bearerToken: _bearerController.text,
      );

  void _loadRequest(SavedRequest r) {
    setState(() {
      _editingId = r.id;
      _lastSavedName = r.name;
      _method = r.method;
      _paramsBase = UrlQuery.parse(r.url).$1;
      _params
        ..clear()
        ..addAll(r.params.isEmpty
            ? UrlQuery.parse(r.url).$2
            : [for (final e in r.params) _copyKv(e)]);
      _headers
        ..clear()
        ..addAll([for (final e in r.headers) _copyKv(e)]);
      _body.kind = r.body?.kind ?? BodyKind.none;
      _body.rawType = r.body?.rawType ?? RawType.json;
      _body.rawContent = r.body?.rawContent ?? '';
      _rawController.text = _body.rawContent;
      _body.formEntries
        ..clear()
        ..addAll([for (final e in (r.body?.formEntries ?? [])) _copyKv(e)]);
      _authKind = r.authKind;
      _bearerController.text = r.bearerToken;
      _timeoutMs = r.timeoutMs;
      _syncingUrl = true;
      _urlController.text = r.url;
    });
    _snack('已载入「${r.name}」');
  }

  // ── 发送 ────────────────────────────────────────────────

  Future<void> _doSend() async {
    if (_sending) return;
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _snack('请输入 URL');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _sending = true);
    final spec = HttpRequestSpec(
      method: _method,
      url: url,
      headers: _headers,
      body: _body,
      authKind: _authKind,
      bearerToken: _bearerController.text,
      timeoutMs: _timeoutMs,
      followRedirects: _followRedirects,
    );
    final r = await (widget.sender ?? HttpSender()).send(spec);
    if (!mounted) return;
    setState(() {
      _result = r;
      _sending = false;
    });
    // 历史自动记录（含完整请求，便于回填重放）；等存储加载完成
    await _storeReady;
    if (!mounted) return;
    _store.addHistory(HistoryEntry(
      time: DateTime.now(),
      request: _snapshot(_lastSavedName ?? _autoName()),
      status: r.status,
      durationMs: r.durationMs,
    ));
  }

  // ── 对话框 ──────────────────────────────────────────────

  Future<void> _openModuleSettings() async {
    final r = await showDialog<({int seconds, bool follow})>(
      context: context,
      builder: (_) => _ModuleSettingsDialog(
        timeoutSeconds: (_timeoutMs / 1000).round(),
        followRedirects: _followRedirects,
      ),
    );
    if (r == null || !mounted) return;
    setState(() {
      _timeoutMs = (r.seconds <= 0 ? 30 : r.seconds) * 1000;
      _followRedirects = r.follow;
    });
  }

  Future<void> _saveDialog() async {
    if (_store.collections.isEmpty) {
      _store.createCollection('默认集合');
    }
    final r = await showDialog<({String name, String collectionId})>(
      context: context,
      builder: (_) => _SaveRequestDialog(
        collections: _store.collections,
        initialName: _lastSavedName ?? _autoName(),
      ),
    );
    if (r == null || !mounted) return;
    final name = r.name.trim().isEmpty ? _autoName() : r.name.trim();
    final req = _snapshot(name);
    _store.saveRequest(r.collectionId, req);
    setState(() {
      _editingId = req.id;
      _lastSavedName = name;
      _expanded.add(r.collectionId);
    });
    final coll =
        _store.collections.where((c) => c.id == r.collectionId).firstOrNull;
    _snack('已保存到「${coll?.name ?? '集合'}」');
  }
  Future<void> _nameDialog(
      String title, String initial, ValueChanged<String> onOk) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(title: title, initial: initial),
    );
    if (name != null) onOk(name.trim());
  }
  Future<void> _confirmDialog(String title, String body, VoidCallback onOk) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        content: Text(body, style: const TextStyle(fontSize: 12.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('删除', style: TextStyle(color: AppColors.err))),
        ],
      ),
    );
    if (ok == true) onOk();
  }

  // ── 布局 ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            _doSend,
      },
      child: Column(
        children: [
          _moduleHeader(),
          Expanded(
            child: Row(
              children: [
                _moduleSide(),
                Container(width: 1, color: AppColors.border),
                Expanded(
                  child: Container(
                    color: AppColors.bg,
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      children: [
                        Flexible(
                          flex: _reqFlex.round(),
                          child: _requestCard(),
                        ),
                        _dragBar(),
                        Expanded(
                          child: ResponseView(
                              result: _result, sending: _sending),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Text('HTTP 测试',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(width: 8),
          const MiniChip('模块 v1.0 · M3', color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                '发送请求（Ctrl Enter）· 超时 ${(_timeoutMs / 1000).round()} s · 重定向${_followRedirects ? '开' : '关'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.aux),
          ),
          _IconAction(Icons.settings_outlined, '模块设置（超时 / 重定向）',
              _openModuleSettings),
        ],
      ),
    );
  }

  // ── 模块侧栏（集合 / 历史 + 本地过滤，M3） ───────────────

  Widget _moduleSide() {
    return Container(
      key: const ValueKey('module_side'),
      width: 196,
      color: AppColors.side,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UnderlineTabs(
            labels: const ['集合', '历史'],
            selectedIndex: _sideTab.index,
            onSelect: (i) => setState(() => _sideTab = HttpSideTab.values[i]),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            child: TextField(
              key: const ValueKey('side_search'),
              controller: _sideQueryCtrl,
              onChanged: (v) => setState(() => _sideQuery = v),
              style: const TextStyle(fontSize: 9.5, color: AppColors.text2),
              decoration: InputDecoration(
                hintText: '搜索（名称 / URL）',
                isDense: true,
                filled: true,
                fillColor: AppColors.fill,
                prefixIcon:
                    const Icon(Icons.search, size: 11, color: AppColors.text4),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 24, minHeight: 24),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                hintStyle:
                    const TextStyle(fontSize: 9.5, color: AppColors.text4),
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
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _sideTab == HttpSideTab.collections
                ? _collectionsView()
                : _historyView(),
          ),
        ],
      ),
    );
  }

  bool _matches(String s) =>
      _sideQuery.trim().isEmpty ||
      s.toLowerCase().contains(_sideQuery.trim().toLowerCase());

  Widget _collectionsView() {
    if (!_storeLoaded) {
      return const Center(
          child: Text('加载中…',
              style: TextStyle(fontSize: 10, color: AppColors.text4)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Text('集合',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text2)),
              const Spacer(),
              _SideIcon(Icons.add, '新建集合', () {
                _nameDialog('新建集合', '', (name) {
                  final c = _store.createCollection(name);
                  _expanded.add(c.id);
                });
              }),
            ],
          ),
        ),
        Expanded(
          child: _store.collections.isEmpty
              ? const Center(
                  child: Text('暂无集合，点 + 新建',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.text4)))
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final c in _store.collections)
                      ..._collectionNode(c),
                  ],
                ),
        ),
      ],
    );
  }

  List<Widget> _collectionNode(RequestCollection c) {
    final expanded = _expanded.contains(c.id);
    final visibleItems =
        _matches(c.name) ? c.items : c.items.where((r) => _matchReq(r)).toList();
    if (!_matches(c.name) && visibleItems.isEmpty) return const <Widget>[];
    return <Widget>[
      InkWell(
        onTap: () => setState(() {
          expanded ? _expanded.remove(c.id) : _expanded.add(c.id);
        }),
        hoverColor: AppColors.hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              Icon(
                expanded ? Icons.expand_more : Icons.chevron_right,
                size: 13,
                color: AppColors.text3,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.folder_open, size: 13, color: AppColors.text3),
              const SizedBox(width: 6),
              Expanded(
                child: Text(c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
              ),
              Text('${c.items.length}',
                  style:
                      const TextStyle(fontSize: 9, color: AppColors.text4)),
              const SizedBox(width: 4),
              _SideIcon(Icons.edit_outlined, '重命名', () {
                _nameDialog('重命名集合', c.name,
                    (name) => _store.renameCollection(c.id, name));
              }),
              _SideIcon(Icons.delete_outline, '删除集合', () {
                _confirmDialog('删除集合', '「${c.name}」及其 ${c.items.length} 个请求将被删除。',
                    () => _store.deleteCollection(c.id));
              }),
            ],
          ),
        ),
      ),
      if (expanded)
        for (final r in visibleItems)
          InkWell(
            key: ValueKey('req_${r.id}'),
            onTap: () => _loadRequest(r),
            hoverColor: AppColors.hover,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 8),
              child: SizedBox(
                height: 26,
                child: Row(
                  children: [
                    MethodBadge(r.method),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.text2)),
                    ),
                    _SideIcon(Icons.close, '删除请求',
                        () => _store.deleteRequest(c.id, r.id)),
                  ],
                ),
              ),
            ),
          ),
    ];
  }

  bool _matchReq(SavedRequest r) =>
      _matches(r.name) || _matches(r.url) || _matches(r.method);

  Widget _historyView() {
    if (!_storeLoaded) {
      return const Center(
          child: Text('加载中…',
              style: TextStyle(fontSize: 10, color: AppColors.text4)));
    }
    final entries = _store.history
        .where((e) => _matches(e.request.url) || _matches(e.request.method))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Text('历史',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text2)),
              Text(' ${_store.history.length}',
                  style:
                      const TextStyle(fontSize: 9, color: AppColors.text4)),
              const Spacer(),
              _SideIcon(Icons.delete_sweep_outlined, '清空历史', () {
                if (_store.history.isEmpty) {
                  _snack('历史为空');
                  return;
                }
                _confirmDialog('清空历史', '将删除全部 ${_store.history.length} 条历史记录。',
                    () => _store.clearHistory());
              }),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text('暂无历史',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.text4)))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final statusColor = e.status == null
                        ? AppColors.err
                        : e.status! >= 500
                            ? AppColors.err
                            : e.status! >= 300
                                ? AppColors.warn
                                : AppColors.ok;
                    return InkWell(
                      onTap: () => _loadRequest(e.request),
                      hoverColor: AppColors.hover,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            MethodBadge(e.request.method),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(e.request.url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.code.copyWith(
                                      fontSize: 10,
                                      color: AppColors.text3)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e.status?.toString() ?? 'ERR',
                              style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.text4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _requestCard() {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _methodSelector(),
              const SizedBox(width: 8),
              Expanded(child: _urlField()),
              const SizedBox(width: 8),
              _sendButton(),
              const SizedBox(width: 8),
              _saveButton(),
            ],
          ),
          const SizedBox(height: 8),
          _UnderlineTabs(
            labels: const ['Params', 'Headers', 'Body', 'Auth'],
            badges: [
              _countEnabled(_params), _countEnabled(_headers), null, null
            ],
            selectedIndex: _reqTab,
            onSelect: (i) => setState(() => _reqTab = i),
          ),
          const SizedBox(height: 6),
          _reqPanel(),
        ],
      ),
    );
  }

  String? _countEnabled(List<KvEntry> list) {
    final n = list.where((e) => e.enabled && e.key.trim().isNotEmpty).length;
    return n == 0 ? null : '$n';
  }

  Widget _methodSelector() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _method,
          items: [
            for (final m in _methods)
              DropdownMenuItem(
                value: m,
                child: Text(m,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: methodColor(m))),
              ),
          ],
          selectedItemBuilder: (context) => [
            for (final m in _methods)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(m,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: methodColor(m))),
                ),
              ),
          ],
          onChanged: (v) => setState(() => _method = v ?? _method),
          icon: const Icon(Icons.arrow_drop_down,
              size: 18, color: AppColors.text3),
          dropdownColor: AppColors.panel,
          borderRadius: BorderRadius.circular(AppRadius.control),
          focusColor: AppColors.accentSoft,
        ),
      ),
    );
  }

  Widget _urlField() {
    return TextField(
      key: const ValueKey('url_field'),
      controller: _urlController,
      focusNode: _urlFocus,
      onChanged: _onUrlChanged,
      style: AppTypography.code.copyWith(fontSize: 11.5),
      decoration: InputDecoration(
        hintText: 'https://…',
        isDense: true,
        filled: true,
        fillColor: AppColors.panel,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
        ),
      ),
    );
  }

  Widget _sendButton() {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: _doSend,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(_sending ? Icons.hourglass_top : Icons.send,
                  size: 13, color: Colors.white),
              const SizedBox(width: 6),
              Text(_sending ? '发送中' : '发送',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return Material(
      color: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: _saveDialog,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Row(
            children: [
              Icon(Icons.save_outlined, size: 12, color: AppColors.text3),
              SizedBox(width: 5),
              Text('保存', style: TextStyle(fontSize: 12, color: AppColors.text3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reqPanel() {
    return switch (_reqTab) {
      0 => KvEditor(
          entries: _params,
          onChanged: _onParamsChanged,
          keyHint: '参数名',
          valueHint: '值',
        ),
      1 => KvEditor(
          entries: _headers,
          onChanged: () => setState(() {}),
          keyHint: 'Header 名',
          valueHint: '值',
        ),
      2 => BodyEditor(
          body: _body,
          rawController: _rawController,
          onChanged: () => setState(() {}),
        ),
      _ => _authPanel(),
    };
  }

  Widget _authPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: [
            _authChip('不使用', AuthKind.none),
            _authChip('Bearer Token', AuthKind.bearer),
          ],
        ),
        if (_authKind == AuthKind.bearer) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 360,
            child: TextField(
              controller: _bearerController,
              style: AppTypography.code.copyWith(fontSize: 11),
              decoration: InputDecoration(
                hintText: '粘贴 Token，发送时自动注入 Authorization 头',
                isDense: true,
                filled: true,
                fillColor: AppColors.fill,
                hintStyle:
                    const TextStyle(fontSize: 10.5, color: AppColors.text4),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.2),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _authChip(String label, AuthKind kind) {
    final selected = _authKind == kind;
    return InkWell(
      onTap: () => setState(() => _authKind = kind),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(label,
            style: AppTypography.nav.copyWith(
                fontSize: 11.5,
                color: selected ? AppColors.text : AppColors.text3,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _dragBar() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        key: const ValueKey('http_split_drag'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) {
          setState(() {
            _reqFlex = (_reqFlex - d.delta.dy / 40).clamp(3.0, 9.0);
          });
        },
        child: Container(
          height: 7,
          margin: const EdgeInsets.symmetric(vertical: 9),
          decoration: const BoxDecoration(
            color: AppColors.fill,
            border: Border(
              top: BorderSide(color: AppColors.borderSoft),
              bottom: BorderSide(color: AppColors.borderSoft),
            ),
          ),
          child: Center(
            child: Container(
              width: 34,
              height: 3,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 小组件 ─────────────────────────────────────────────────

/// 名称输入对话框（自管理控制器生命周期）。
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, this.initial = ''});
  final String title;
  final String initial;
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(isDense: true, hintText: '名称'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, _ctrl.text),
              child: const Text('确定',
                  style: TextStyle(color: AppColors.accent))),
        ],
      );
}

/// 保存请求对话框：名称 + 目标集合。
class _SaveRequestDialog extends StatefulWidget {
  const _SaveRequestDialog({
    required this.collections,
    required this.initialName,
  });
  final List<RequestCollection> collections;
  final String initialName;
  @override
  State<_SaveRequestDialog> createState() => _SaveRequestDialogState();
}

class _SaveRequestDialogState extends State<_SaveRequestDialog> {
  late final TextEditingController _name;
  late String _collId;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _collId = widget.collections.first.id;
  }
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('保存请求', style: TextStyle(fontSize: 14)),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('save_name_field'),
                controller: _name,
                decoration: const InputDecoration(
                    labelText: '请求名称', isDense: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _collId,
                decoration: const InputDecoration(
                    labelText: '保存到集合', isDense: true),
                items: [
                  for (final c in widget.collections)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _collId = v ?? _collId),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(
                  context, (name: _name.text, collectionId: _collId)),
              child: const Text('确定',
                  style: TextStyle(color: AppColors.accent))),
        ],
      );
}

/// 模块设置：超时 + 跟随重定向。
class _ModuleSettingsDialog extends StatefulWidget {
  const _ModuleSettingsDialog({
    required this.timeoutSeconds,
    required this.followRedirects,
  });
  final int timeoutSeconds;
  final bool followRedirects;
  @override
  State<_ModuleSettingsDialog> createState() => _ModuleSettingsDialogState();
}

class _ModuleSettingsDialogState extends State<_ModuleSettingsDialog> {
  late final TextEditingController _timeout;
  late bool _follow;
  @override
  void initState() {
    super.initState();
    _timeout = TextEditingController(text: widget.timeoutSeconds.toString());
    _follow = widget.followRedirects;
  }
  @override
  void dispose() {
    _timeout.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('模块设置', style: TextStyle(fontSize: 14)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _timeout,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: '超时（秒）', isDense: true),
              ),
              SwitchListTile(
                value: _follow,
                onChanged: (v) => setState(() => _follow = v),
                title: const Text('跟随重定向（3xx）',
                    style: TextStyle(fontSize: 13)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, (
                    seconds: int.tryParse(_timeout.text) ?? 30,
                    follow: _follow,
                  )),
              child: const Text('保存',
                  style: TextStyle(color: AppColors.accent))),
        ],
      );
}
class _SideIcon extends StatelessWidget {
  const _SideIcon(this.icon, this.tooltip, this.onTap);

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: AppColors.hover,
        child: SizedBox(
          width: 20,
          height: 20,
          child: Icon(icon, size: 11, color: AppColors.text3),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction(this.icon, this.tooltip, this.onTap);

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        hoverColor: AppColors.hover,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 14, color: AppColors.text3),
        ),
      ),
    );
  }
}

class _UnderlineTabs extends StatelessWidget {
  const _UnderlineTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
    this.badges,
  });

  final List<String> labels;
  final int selectedIndex;
  final void Function(int index) onSelect;
  final List<String?>? badges;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          InkWell(
            onTap: () => onSelect(i),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(labels[i],
                          style: AppTypography.nav.copyWith(
                              fontSize: 11.5,
                              fontWeight: i == selectedIndex
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: i == selectedIndex
                                  ? AppColors.text
                                  : AppColors.text3)),
                      if (badges != null &&
                          i < badges!.length &&
                          badges![i] != null) ...[
                        const SizedBox(width: 4),
                        MiniChip(badges![i]!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 2,
                    width: 28,
                    color: i == selectedIndex
                        ? AppColors.accent
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class MethodBadge extends StatelessWidget {
  const MethodBadge(this.method, {super.key});

  final String method;

  @override
  Widget build(BuildContext context) {
    final color = methodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(method,
          style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: color)),
    );
  }
}





