import 'dart:ui';
import 'package:flutter/material.dart';

/// Componente base de Liquid Glass (Glassmorfismo estilo SwiftUI)
/// Proporciona desfoque de fundo (BackdropFilter), borda reflexiva especular
/// e gradientes sutis simulando a refração de luz no vidro líquido.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadows;
  final Color? tintColor;
  final Gradient? customGradient;
  final double? width;
  final double? height;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.blur = 18.0,
    this.opacity = 0.12,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.shadows,
    this.tintColor,
    this.customGradient,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(24);

    final defaultBorder = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.65),
      width: 1.2,
    );

    final defaultShadows = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: (tintColor ?? (isDark ? Colors.purple : Colors.blue))
            .withValues(alpha: isDark ? 0.08 : 0.04),
        blurRadius: 30,
        offset: const Offset(0, 4),
      ),
    ];

    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              (tintColor ?? Colors.white).withValues(alpha: opacity * 1.5),
              (tintColor ?? Colors.white).withValues(alpha: opacity * 0.6),
            ]
          : [
              Colors.white.withValues(alpha: opacity * 2.8),
              Colors.white.withValues(alpha: opacity * 1.2),
            ],
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows ?? defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: border ?? defaultBorder,
              gradient: customGradient ?? defaultGradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Pill/Badge interativo com toque de vidro líquido estilo iOS
class LiquidGlassPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? glowColor;
  final EdgeInsetsGeometry padding;

  const LiquidGlassPill({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.glowColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = glowColor ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.8)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.5)),
                  width: isSelected ? 1.4 : 1.0,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          color.withValues(alpha: 0.85),
                          color.withValues(alpha: 0.65),
                        ]
                      : [
                          isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.65),
                          isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.white.withValues(alpha: 0.35),
                        ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
