import 'dart:ui';
import 'package:flutter/material.dart';

/// Fundo dinâmico com orbes orgânicos líquidos estilo SwiftUI & Glassmorphism
/// Cria as cores fluidas de fundo necessárias para que o efeito de vidro fosco
/// (BackdropFilter) refrate a luz perfeitamente.
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
        // Cor base profunda
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF0B0D14) : const Color(0xFFF3F5FA),
          ),
        ),

        // Orbe 1: Superior Esquerdo (Índigo / Roxo elétrico)
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                        Colors.transparent,
                      ]
                    : [
                        const Color(0xFFA29BFE).withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),

        // Orbe 2: Centro Direito (Ciano elétrico do TikTok / Azul X)
        Positioned(
          top: 240,
          right: -90,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        const Color(0xFF00CEC9).withValues(alpha: 0.22),
                        const Color(0xFF0984E3).withValues(alpha: 0.15),
                        Colors.transparent,
                      ]
                    : [
                        const Color(0xFF81ECEC).withValues(alpha: 0.4),
                        const Color(0xFF74B9FF).withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),

        // Orbe 3: Inferior Esquerdo (Magenta / Laranja do Instagram)
        Positioned(
          bottom: 40,
          left: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        const Color(0xFFE84393).withValues(alpha: 0.25),
                        const Color(0xFFFD79A8).withValues(alpha: 0.1),
                        Colors.transparent,
                      ]
                    : [
                        const Color(0xFFFD79A8).withValues(alpha: 0.35),
                        const Color(0xFFFAB1A0).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),

        // Camada de difusão de desfoque ultra suave para misturar os orbes
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: const SizedBox.expand(),
          ),
        ),

        // Conteúdo da aplicação por cima do vidro líquido
        child,
      ],
    );
  }
}
