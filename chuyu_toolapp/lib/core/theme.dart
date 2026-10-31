import 'package:flutter/material.dart';

/// 设计 token（SPEC §7.2 / §7.3 / §7.6）。
/// 页面与模块禁止写死颜色、字号、间距，一律从这里读取。
abstract final class AppColors {
  // 结构
  static const Color bg = Color(0xFFF5F6F8);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color side = Color(0xFFFBFBFD);
  static const Color fill = Color(0xFFF4F6F9);
  static const Color border = Color(0xFFE8EAF0);
  static const Color borderSoft = Color(0xFFEFF1F5);
  // 文字
  static const Color text = Color(0xFF191C22);
  static const Color text2 = Color(0xFF505966);
  static const Color text3 = Color(0xFF8A92A1);
  static const Color text4 = Color(0xFFA9B0BC);
  // 强调（唯一强调色）
  static const Color accent = Color(0xFF2F6BFF);
  static const Color accentDark = Color(0xFF1F4FD8);
  static const Color accentSoft = Color(0xFFEEF3FF);
  static const Color accentBorder = Color(0xFFD9E4FF);
  // 语义
  static const Color ok = Color(0xFF0B8A4B);
  static const Color okBg = Color(0xFFE8F7EE);
  static const Color warn = Color(0xFFA8690A);
  static const Color warnBg = Color(0xFFFDF3E2);
  static const Color err = Color(0xFFD13F34);
  static const Color errBg = Color(0xFFFDECEA);
  // 方法徽标
  static const Color put = Color(0xFF2563EB);
  static const Color patch = Color(0xFF7C5CD6);
  // 其它
  static const Color scrim = Color(0x42111827); // rgba(17,24,39,.26)
  static const Color hover = Color(0x0A101828); // rgba(16,24,40,.045)
  // JSON 着色
  static const Color jsonKey = Color(0xFF6B4EE6);
  static const Color jsonStr = Color(0xFF0B8A4B);
  static const Color jsonNum = Color(0xFFB06F08);
  static const Color jsonPunct = Color(0xFF9AA2B0);
}

abstract final class AppTypography {
  static const TextStyle h1 = TextStyle(
      fontSize: 23, height: 1.34, fontWeight: FontWeight.w600, color: AppColors.text);
  static const TextStyle title = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text);
  static const TextStyle body = TextStyle(
      fontSize: 11.5, height: 1.75, color: AppColors.text2);
  static const TextStyle nav = TextStyle(fontSize: 12, color: AppColors.text);
  static const TextStyle section = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2);
  static const TextStyle aux = TextStyle(fontSize: 10, color: AppColors.text3);
  static const TextStyle code = TextStyle(
      fontSize: 10,
      height: 1.63,
      color: AppColors.text,
      fontFamily: 'Cascadia Code',
      fontFamilyFallback: <String>['Cascadia Mono', 'Consolas']);
}

abstract final class AppSpacing {
  static const double pagePad = 26;
  static const double sectionGap = 24;
  static const double cardPad = 14;
}

abstract final class AppRadius {
  static const double window = 12;
  static const double card = 10;
  static const double control = 7;
  static const double badge = 4;
}

/// HTTP 方法徽标配色（SPEC §7.2）。
Color methodColor(String method) => switch (method.toUpperCase()) {
      'GET' => AppColors.ok,
      'POST' => AppColors.warn,
      'PUT' => AppColors.put,
      'PATCH' => AppColors.patch,
      _ => AppColors.err,
    };

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Segoe UI',
    fontFamilyFallback: const <String>[
      'Segoe UI Variable Text',
      'Microsoft YaHei UI',
      'PingFang SC',
    ],
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.panel,
      error: AppColors.err,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.panel,
      contentTextStyle: const TextStyle(fontSize: 12, color: AppColors.text),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll<Color>(Color(0xFFFFFFFF)),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) =>
          states.contains(WidgetState.selected) ? AppColors.accent : AppColors.border),
      trackOutlineColor:
          const WidgetStatePropertyAll<Color>(AppColors.borderSoft),
    ),
  );
}
