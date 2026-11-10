import 'package:flutter/material.dart';

/// Fundo atmosférico moderno e clean com gradientes suaves e isolado em RepaintBoundary
/// para máxima fluidez de rolagem (60/120fps) sem custo de BackdropFilter em tela cheia.
class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        RepaintBoundary(
          child: Stack(
            children: [
              // Base clean
              Positioned.fill(
                child: ColoredBox(
                  color:
                      isDark ? const Color(0xFF090B10) : const Color(0xFFF6F7FB),
                ),
              ),

              // Luz ambiente 1: Superior Esquerdo (Índigo / Violeta suave)
              Positioned(
                top: -120,
                left: -100,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF6C5CE7).withValues(alpha: 0.18),
                              const Color(0xFF6C5CE7).withValues(alpha: 0.05),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                              const Color(0xFFA29BFE).withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // Luz ambiente 2: Superior Direito (Ciano / Azul sutil)
              Positioned(
                top: 140,
                right: -140,
                child: Container(
                  width: 440,
                  height: 440,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF00CEC9).withValues(alpha: 0.10),
                              const Color(0xFF0984E3).withValues(alpha: 0.03),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF74B9FF).withValues(alpha: 0.12),
                              const Color(0xFF81ECEC).withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // Luz ambiente 3: Inferior Esquerdo (Rosa / Coral discreto)
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              const Color(0xFFE84393).withValues(alpha: 0.10),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFFFD79A8).withValues(alpha: 0.10),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Conteúdo principal
        child,
      ],
    );
  }
}
