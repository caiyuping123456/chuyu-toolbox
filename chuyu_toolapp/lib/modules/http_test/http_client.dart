import 'dart:convert';

import 'package:dio/dio.dart';

import 'models.dart';

/// dio 封装：HTTP 测试模块唯一的网络出口（SPEC §6）。
class HttpSender {
  HttpSender({Dio? dio}) : _dioOverride = dio;

  final Dio? _dioOverride;

  Future<HttpResult> send(HttpRequestSpec spec) async {
    final stopwatch = Stopwatch()..start();
    final dio = _dioOverride ??
        Dio(BaseOptions(
          validateStatus: (_) => true, // 任何状态码都算"收到响应"，不抛异常
          followRedirects: spec.followRedirects,
          maxRedirects: 10,
          connectTimeout: Duration(milliseconds: spec.timeoutMs),
          receiveTimeout: Duration(milliseconds: spec.timeoutMs),
          sendTimeout: Duration(milliseconds: spec.timeoutMs),
          responseType: ResponseType.plain, // 拿原始文本，由界面决定怎么展示
        ));

    try {
      final headers = <String, String>{
        for (final h in spec.headers)
          if (h.enabled && h.key.trim().isNotEmpty) h.key.trim(): h.value,
      };
      if (spec.authKind == AuthKind.bearer && spec.bearerToken.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${spec.bearerToken.trim()}';
      }

      Object? data;
      String? contentType;
      final body = spec.body;
      switch (body?.kind) {
        case null:
        case BodyKind.none:
          data = null;
        case BodyKind.raw:
          data = body!.rawContent;
          if (!headers.containsKey('Content-Type')) {
            contentType = switch (body.rawType) {
              RawType.json => 'application/json',
              RawType.text => 'text/plain',
              RawType.xml => 'application/xml',
              RawType.html => 'text/html',
            };
          }
        case BodyKind.urlEncoded:
          data = <String, String>{
            for (final e in body!.formEntries)
              if (e.enabled && e.key.trim().isNotEmpty) e.key.trim(): e.value,
          };
          contentType = 'application/x-www-form-urlencoded';
        case BodyKind.formData:
          data = FormData.fromMap(<String, String>{
            for (final e in body!.formEntries)
              if (e.enabled && e.key.trim().isNotEmpty) e.key.trim(): e.value,
          });
      }

      final response = await dio.request<String>(
        spec.url,
        data: data,
        options: Options(
          method: spec.method,
          headers: headers,
          contentType: contentType,
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
          followRedirects: spec.followRedirects,
        ),
      );
      stopwatch.stop();

      final bodyText = response.data ?? '';
      return HttpResult(
        status: response.statusCode,
        phrase: statusPhrase(response.statusCode ?? 0),
        headers: {
          for (final e in response.headers.map.entries)
            e.key: e.value.join('; '),
        },
        body: bodyText,
        durationMs: stopwatch.elapsedMilliseconds,
        sizeBytes: utf8.encode(bodyText).length,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      return HttpResult(
        durationMs: stopwatch.elapsedMilliseconds,
        error: _dioMessage(e),
      );
    } catch (e) {
      stopwatch.stop();
      return HttpResult(
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      );
    }
  }

  static String _dioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时（${e.message ?? ''}）';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.connectionError:
        final inner = e.error?.toString() ?? e.message ?? '';
        return '连接失败：$inner'.trim();
      case DioExceptionType.badResponse:
        return '响应异常：${e.message ?? ''}';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.badCertificate:
        return '证书校验失败';
      default:
        return e.message ?? '请求失败';
    }
  }
}
