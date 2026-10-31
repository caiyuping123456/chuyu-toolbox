import 'dart:math';

/// UUID v4 生成（纯随机，无依赖）。
abstract final class UuidService {
  static final Random _r = Random.secure();

  static String _hex(int n) => n.toRadixString(16).padLeft(2, '0');

  static String v4() {
    final b = List<int>.generate(16, (_) => _r.nextInt(256));
    b[6] = (b[6] & 0x0F) | 0x40; // version 4
    b[8] = (b[8] & 0x3F) | 0x80; // variant 10
    final h = b.map(_hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static List<String> generate(int count) {
    final n = count.clamp(1, 1000);
    return List<String>.generate(n, (_) => v4());
  }
}
