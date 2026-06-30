import 'package:flutter/material.dart';

import '../../theme/chavrusa_directory_theme.dart';

enum BrutalistButtonStyle { primary, secondary, login, contact }

class BrutalistButton extends StatefulWidget {
  const BrutalistButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = BrutalistButtonStyle.primary,
    this.icon,
    this.minHeight = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });

  final String label;
  final VoidCallback? onPressed;
  final BrutalistButtonStyle style;
  final Widget? icon;
  final double minHeight;
  final EdgeInsets padding;

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final isPrimary = widget.style != BrutalistButtonStyle.secondary;
    final bg = switch (widget.style) {
      BrutalistButtonStyle.secondary => Colors.white,
      _ => _pressed && enabled
          ? ChavrusaDirectoryTheme.blueDark
          : ChavrusaDirectoryTheme.blue,
    };
    final fg = isPrimary ? Colors.white : ChavrusaDirectoryTheme.ink;
    final offset = _pressed && enabled ? 3.0 : 0.0;
    final shadow = _pressed && enabled ? 0.0 : (widget.style == BrutalistButtonStyle.contact ? 3.0 : 4.0);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          transform: Matrix4.translationValues(offset, offset, 0),
          decoration: BoxDecoration(
            color: enabled ? bg : bg.withValues(alpha: 0.55),
            border: Border.all(color: ChavrusaDirectoryTheme.line),
            boxShadow: [
              BoxShadow(
                color: ChavrusaDirectoryTheme.shadow,
                offset: Offset(shadow, shadow),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            child: Padding(
              padding: widget.padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: widget.style == BrutalistButtonStyle.contact ? 10 : 14,
                      letterSpacing: widget.style == BrutalistButtonStyle.contact ? 0.3 : 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
