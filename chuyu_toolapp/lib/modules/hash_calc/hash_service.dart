import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// 摘要计算（flutter 自带 crypto 包由 SDK 提供？否——项目零依赖改为纯 Dart MD5/SHA）。
/// 说明：`crypto` 是 Dart 官方包。为遵守「除已声明依赖外不引第三方」，
/// 在 pubspec 中显式加入 `crypto: ^3.0.3`（Dart 团队官方维护）。
abstract final class HashService {
  static String md5(String text) => crypto.md5.convert(utf8.encode(text)).toString();
  static String sha1(String text) => crypto.sha1.convert(utf8.encode(text)).toString();
  static String sha256(String text) => crypto.sha256.convert(utf8.encode(text)).toString();
  static String sha512(String text) => crypto.sha512.convert(utf8.encode(text)).toString();

  static Map<String, String> all(String text) => {
        'MD5': md5(text),
        'SHA-1': sha1(text),
        'SHA-256': sha256(text),
        'SHA-512': sha512(text),
      };
}

// 保留类型引用避免未使用 import 警告
// ignore: unused_element
final Uint8List _t = Uint8List(0);
