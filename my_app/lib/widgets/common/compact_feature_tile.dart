import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Compact, accessible 2-column feature tile designed to replace long
/// horizontal cards throughout the GPDI Church App.
///
/// Features:
/// - Distinct soft-tinted icon container
/// - Bold, high-contrast title
/// - Action hint with arrow (e.g. "Kelola akun →", "Baca firman →")
/// - Accessible touch target (>= 48dp)
/// - Flexible height scaling for text enlargement without RenderFlex overflow
class CompactFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String actionLabel;
  final Color accentColor;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;

  const CompactFeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.accentColor,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neutralBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 100),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accentColor, size: 22),
                      ),
                      if (badgeText != null && badgeText!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? accentColor).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor ?? accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.darkCharcoal,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

/// Helper container that arranges [CompactFeatureTile]s into a responsive 2-column layout
/// without rigid aspect-ratio clipping when accessibility text zoom is applied.
class CompactFeatureGrid extends StatelessWidget {
  final List<CompactFeatureTile> tiles;
  final double spacing;

  const CompactFeatureGrid({
    super.key,
    required this.tiles,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 280;

        if (isSingleColumn) {
          return Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i < tiles.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }

        final List<Widget> rows = [];
        for (int i = 0; i < tiles.length; i += 2) {
          final first = tiles[i];
          final second = i + 1 < tiles.length ? tiles[i + 1] : null;

          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: first),
                  SizedBox(width: spacing),
                  if (second != null)
                    Expanded(child: second)
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          );

          if (i + 2 < tiles.length) {
            rows.add(SizedBox(height: spacing));
          }
        }

        return Column(
          children: rows,
        );
      },
    );
  }
}
