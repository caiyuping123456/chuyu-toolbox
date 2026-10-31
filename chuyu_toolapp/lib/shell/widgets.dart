import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 白底细边卡片（SPEC §7.2 / §7.6 组件映射）。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPad),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    final shape =
        RoundedRectangleBorder(borderRadius: radius, side: const BorderSide(color: AppColors.border));
    return Material(
      color: AppColors.panel,
      shape: shape,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              customBorder: shape,
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}

/// 区块小标题。
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: AppTypography.section.copyWith(letterSpacing: 0.6),
      ),
    );
  }
}

/// 小标记（可用 / 二期 / Ctrl K …）。
class MiniChip extends StatelessWidget {
  const MiniChip(this.text, {super.key, this.color, this.background});

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
            fontSize: 9.5, height: 1.5, color: color ?? AppColors.text3),
      ),
    );
  }
}

/// 导航项：选中态 = 白色卡片 + 细边 + 小阴影（SPEC §7.4）。
class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.trailing,
    this.iconOnly = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.control);

    if (iconOnly) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: selected ? AppColors.accentSoft : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                  color: selected ? AppColors.accentBorder : Colors.transparent),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: RoundedRectangleBorder(borderRadius: radius),
              hoverColor: AppColors.hover,
              child: SizedBox(
                width: 40,
                height: 32,
                child: Icon(icon,
                    size: 16,
                    color: selected ? AppColors.accent : AppColors.text3),
              ),
            ),
          ),
        ),
      );
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Icon(icon,
              size: 15, color: selected ? AppColors.accent : AppColors.text3),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.nav.copyWith(
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400),
            ),
          ),
          ?trailing,
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: selected
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: radius,
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                      color: Color(0x0D101828),
                      blurRadius: 4,
                      offset: Offset(0, 1)),
                ],
              ),
              child: content,
            )
          : InkWell(
              onTap: onTap,
              borderRadius: radius,
              hoverColor: AppColors.hover,
              child: content,
            ),
    );
  }
}
