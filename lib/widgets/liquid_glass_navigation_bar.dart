import 'package:flutter/material.dart';

import 'liquid_glass.dart';

class LiquidNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const LiquidNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Floating Liquid Glass Navigation Bar no estilo SwiftUI e iOS Dynamic Island
class LiquidGlassNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<LiquidNavItem> items;

  const LiquidGlassNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: LiquidGlassContainer(
            blur: 26,
            opacity: isDark ? 0.2 : 0.34,
            borderRadius: BorderRadius.circular(38),
            padding: const EdgeInsets.all(5),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedAlign(
                    alignment: Alignment(
                      items.length == 1
                          ? 0
                          : 2 * selectedIndex / (items.length - 1) - 1,
                      0,
                    ),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: FractionallySizedBox(
                      widthFactor: 1 / items.length,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(
                            alpha: isDark ? 0.22 : 0.11,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      for (final (index, item) in items.indexed)
                        Expanded(
                          child: Semantics(
                            selected: index == selectedIndex,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(32),
                              onTap: () => onItemSelected(index),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      index == selectedIndex
                                          ? item.selectedIcon
                                          : item.icon,
                                      color: index == selectedIndex
                                          ? colors.primary
                                          : colors.onSurfaceVariant,
                                      size: 21,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: index == selectedIndex
                                            ? colors.primary
                                            : colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
