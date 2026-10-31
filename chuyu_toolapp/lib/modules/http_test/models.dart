/// HTTP 测试模块数据模型（SPEC §6 / §8，JSON 字段与存储格式一致，M3 直接复用）。
library;

class KvEntry {
  KvEntry({
    String? id,
    this.enabled = true,
    this.key = '',
    this.value = '',
    this.note = '',
  }) : id = id ?? 'kv_${_nextId()}';

  static int _counter = 0;
  static int _nextId() => ++_counter;

  final String id;
  bool enabled;
  String key;
  String value;
  String note;

  Map<String, dynamic> toJson() =>
      {'enabled': enabled, 'key': key, 'value': value, 'note': note};

  factory KvEntry.fromJson(Map<String, dynamic> json) => KvEntry(
        enabled: json['enabled'] as bool? ?? true,
        key: json['key'] as String? ?? '',
        value: json['value'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}

enum BodyKind { none, formData, urlEncoded, raw }

enum RawType { json, text, xml, html }

enum AuthKind { none, bearer }

class HttpBodySpec {
  HttpBodySpec({
    this.kind = BodyKind.none,
    this.rawType = RawType.json,
    this.rawContent = '',
    List<KvEntry>? formEntries,
  }) : formEntries = formEntries ?? <KvEntry>[];

  BodyKind kind;
  RawType rawType;
  String rawContent;
  List<KvEntry> formEntries;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'rawType': rawType.name,
        'rawContent': rawContent,
        'formEntries': [for (final e in formEntries) e.toJson()],
      };

  factory HttpBodySpec.fromJson(Map<String, dynamic> json) => HttpBodySpec(
        kind: BodyKind.values.firstWhere(
            (v) => v.name == json['kind'],
            orElse: () => BodyKind.none),
        rawType: RawType.values.firstWhere(
            (v) => v.name == json['rawType'],
            orElse: () => RawType.json),
        rawContent: json['rawContent'] as String? ?? '',
        formEntries: [
          for (final e in (json['formEntries'] as List? ?? <dynamic>[]))
            KvEntry.fromJson(e as Map<String, dynamic>)
        ],
      );
}

class HttpRequestSpec {
  HttpRequestSpec({
    required this.method,
    required this.url,
    this.params = const <KvEntry>[],
    this.headers = const <KvEntry>[],
    this.body,
    this.authKind = AuthKind.none,
    this.bearerToken = '',
    this.timeoutMs = 30000,
    this.followRedirects = true,
  });

  final String method;
  final String url;
  final List<KvEntry> params;
  final List<KvEntry> headers;
  final HttpBodySpec? body;
  final AuthKind authKind;
  final String bearerToken;
  final int timeoutMs;
  final bool followRedirects;
}

class HttpResult {
  HttpResult({
    this.status,
    this.phrase = '',
    this.headers = const <String, String>{},
    this.body = '',
    this.durationMs = 0,
    this.sizeBytes = 0,
    this.error,
  });

  final int? status; // null = 网络层失败
  final String phrase;
  final Map<String, String> headers;
  final String body;
  final int durationMs;
  final int sizeBytes;
  final String? error;

  bool get hasError => error != null;

  /// 2xx 绿 / 3xx 黄(警示) / 4xx 橙(警示) / 5xx 红（SPEC §6.2）
  int get statusClass {
    final s = status ?? 0;
    if (s >= 200 && s < 300) return 2;
    if (s >= 300 && s < 400) return 3;
    if (s >= 400 && s < 500) return 4;
    if (s >= 500) return 5;
    return 0;
  }

  String get statusText => status == null ? '失败' : '$status ${phrase.isEmpty ? '' : phrase}'.trim();
}

String statusPhrase(int code) => switch (code) {
      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      204 => 'No Content',
      301 => 'Moved Permanently',
      302 => 'Found',
      304 => 'Not Modified',
      307 => 'Temporary Redirect',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      409 => 'Conflict',
      429 => 'Too Many Requests',
      500 => 'Internal Server Error',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      _ => '',
    };

/// URL ↔ Params 双向同步（SPEC §6.1：URL 单行输入与 Params 表双向同步）。
class UrlQuery {
  /// 解析 URL：返回 (不含 query 的 base, 参数列表)。解析失败时返回原串与空表。
  static (String, List<KvEntry>) parse(String url) {
    final noFrag = url.split('#').first;
    final i = noFrag.indexOf('?');
    if (i == -1) return (noFrag, <KvEntry>[]);
    final base = noFrag.substring(0, i);
    final query = noFrag.substring(i + 1);
    final entries = <KvEntry>[];
    for (final seg in query.split('&')) {
      if (seg.isEmpty) continue;
      final j = seg.indexOf('=');
      String k;
      String v;
      try {
        k = Uri.decodeQueryComponent(j == -1 ? seg : seg.substring(0, j));
        v = j == -1 ? '' : Uri.decodeQueryComponent(seg.substring(j + 1));
      } catch (_) {
        k = j == -1 ? seg : seg.substring(0, j);
        v = j == -1 ? '' : seg.substring(j + 1);
      }
      entries.add(KvEntry(enabled: true, key: k, value: v));
    }
    return (base, entries);
  }

  /// 用参数表重建 URL（仅启用且 key 非空的项）。
  static String build(String base, List<KvEntry> entries) {
    final pairs = entries
        .where((e) => e.enabled && e.key.trim().isNotEmpty)
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .toList();
    return pairs.isEmpty ? base : '$base?${pairs.join('&')}';
  }
}

// ── 持久化模型（SPEC §8，collections.json / history.json） ──────

int _seq = 0;
String _newId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${++_seq}';

class SavedRequest {
  SavedRequest({
    String? id,
    required this.name,
    required this.method,
    required this.url,
    this.params = const <KvEntry>[],
    this.headers = const <KvEntry>[],
    this.body,
    this.timeoutMs = 30000,
    this.authKind = AuthKind.none,
    this.bearerToken = '',
  }) : id = id ?? _newId('req');

  final String id;
  String name;
  String method;
  String url;
  List<KvEntry> params;
  List<KvEntry> headers;
  HttpBodySpec? body;
  int timeoutMs;
  AuthKind authKind;
  String bearerToken;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'method': method,
        'url': url,
        'params': [for (final e in params) e.toJson()],
        'headers': [for (final e in headers) e.toJson()],
        'body': body?.toJson(),
        'timeoutMs': timeoutMs,
        'authKind': authKind.name,
        'bearerToken': bearerToken,
      };

  factory SavedRequest.fromJson(Map<String, dynamic> json) => SavedRequest(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        method: json['method'] as String? ?? 'GET',
        url: json['url'] as String? ?? '',
        params: [
          for (final e in (json['params'] as List? ?? <dynamic>[]))
            KvEntry.fromJson(e as Map<String, dynamic>)
        ],
        headers: [
          for (final e in (json['headers'] as List? ?? <dynamic>[]))
            KvEntry.fromJson(e as Map<String, dynamic>)
        ],
        body: json['body'] == null
            ? null
            : HttpBodySpec.fromJson(json['body'] as Map<String, dynamic>),
        timeoutMs: json['timeoutMs'] as int? ?? 30000,
        authKind: AuthKind.values.firstWhere(
            (v) => v.name == json['authKind'],
            orElse: () => AuthKind.none),
        bearerToken: json['bearerToken'] as String? ?? '',
      );
}

class RequestCollection {
  RequestCollection(
      {String? id, required this.name, List<SavedRequest>? items})
      : id = id ?? _newId('coll'),
        items = items ?? <SavedRequest>[];

  final String id;
  String name;
  List<SavedRequest> items;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': [for (final r in items) r.toJson()],
      };

  factory RequestCollection.fromJson(Map<String, dynamic> json) =>
      RequestCollection(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '未命名集合',
        items: [
          for (final r in (json['items'] as List? ?? <dynamic>[]))
            SavedRequest.fromJson(r as Map<String, dynamic>)
        ],
      );
}

class HistoryEntry {
  HistoryEntry({
    required this.time,
    required this.request,
    this.status,
    this.durationMs = 0,
  });

  final DateTime time;
  final SavedRequest request;
  final int? status; // null = 网络失败
  final int durationMs;

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'request': request.toJson(),
        'status': status,
        'durationMs': durationMs,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        time: DateTime.tryParse(json['time'] as String? ?? '') ??
            DateTime.now(),
        request:
            SavedRequest.fromJson(json['request'] as Map<String, dynamic>),
        status: json['status'] as int?,
        durationMs: json['durationMs'] as int? ?? 0,
      );
}


