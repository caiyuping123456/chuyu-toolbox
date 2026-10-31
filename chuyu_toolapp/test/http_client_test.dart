import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chuyu_toolapp/modules/http_test/http_client.dart';
import 'package:chuyu_toolapp/modules/http_test/models.dart';

Future<HttpServer> startEchoServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    final body = await utf8.decoder.bind(req).join();
    if (req.uri.path == '/notfound') {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    req.response.statusCode = 200;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode({
      'method': req.method,
      'query': req.uri.queryParameters,
      'body': body,
      'contentType': req.headers.value('content-type') ?? '',
      'authorization': req.headers.value('authorization') ?? '',
    }));
    await req.response.close();
  });
  return server;
}

void main() {
  test('GET：状态 / 短语 / 耗时 / 体积 / 响应头 / query 传递', () async {
    final s = await startEchoServer();
    final url = 'http://127.0.0.1:${s.port}/echo?page=1&size=10';
    final r = await HttpSender()
        .send(HttpRequestSpec(method: 'GET', url: url));
    expect(r.hasError, isFalse);
    expect(r.status, 200);
    expect(r.phrase, 'OK');
    expect(r.durationMs, greaterThanOrEqualTo(0));
    expect(r.sizeBytes, greaterThan(0));
    expect(r.body, contains('page'));
    expect(r.body, contains('"query"'));
    expect(r.headers.containsKey('content-type'), isTrue);
    await s.close(force: true);
  });

  test('POST：raw JSON Body + Content-Type 自动设置 + 404 状态短语', () async {
    final s = await startEchoServer();
    final payload = '{"username":"demo"}';
    final ok = await HttpSender().send(HttpRequestSpec(
      method: 'POST',
      url: 'http://127.0.0.1:${s.port}/echo',
      body: HttpBodySpec(kind: BodyKind.raw, rawType: RawType.json, rawContent: payload),
    ));
    expect(ok.status, 200);
    expect(ok.body, contains('demo'), reason: '应回显请求体');
    expect(ok.body, contains('username'));
    expect(ok.body.toLowerCase(), contains('application/json'));

    final nf = await HttpSender().send(
        HttpRequestSpec(method: 'GET', url: 'http://127.0.0.1:${s.port}/notfound'));
    expect(nf.status, 404);
    expect(nf.phrase, 'Not Found');
    await s.close(force: true);
  });

  test('x-www-form-urlencoded 与 Bearer 头注入', () async {
    final s = await startEchoServer();
    final r = await HttpSender().send(HttpRequestSpec(
      method: 'POST',
      url: 'http://127.0.0.1:${s.port}/echo',
      body: HttpBodySpec(
        kind: BodyKind.urlEncoded,
        formEntries: [
          KvEntry(key: 'a', value: '1'),
          KvEntry(key: 'b', value: '2', enabled: false), // 禁用项不发送
        ],
      ),
      authKind: AuthKind.bearer,
      bearerToken: 'tk123',
    ));
    expect(r.status, 200);
    expect(r.body, contains('a=1'));
    expect(r.body, isNot(contains('b=2')));
    expect(r.body, contains('Bearer tk123'));
    await s.close(force: true);
  });

  test('网络错误：连接失败被归类为错误结果', () async {
    final s = await startEchoServer();
    final port = s.port; // 占住端口后关闭，制造"连接拒绝"
    await s.close(force: true);
    final r = await HttpSender().send(
        HttpRequestSpec(method: 'GET', url: 'http://127.0.0.1:$port/echo'));
    expect(r.hasError, isTrue);
    expect(r.status, isNull);
    expect(r.error, isNotEmpty);
  });

  test('URL ↔ Params 同步：parse / build 往返', () {
    final (base, entries) =
        UrlQuery.parse('https://a.com/x?page=1&size=10#frag');
    expect(base, 'https://a.com/x');
    expect(entries, hasLength(2));
    expect(entries.first.key, 'page');
    expect(entries.first.value, '1');

    entries.last.enabled = false;
    expect(UrlQuery.build(base, entries), 'https://a.com/x?page=1');

    entries.last.enabled = true;
    expect(UrlQuery.build(base, entries),
        'https://a.com/x?page=1&size=10');

    final (b2, e2) = UrlQuery.parse('https://a.com/y');
    expect(b2, 'https://a.com/y');
    expect(e2, isEmpty);
  });
}
