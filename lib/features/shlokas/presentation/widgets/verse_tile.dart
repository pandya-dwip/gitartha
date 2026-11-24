import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/sacred_widgets.dart';
import '../../../../data/local/database/app_database.dart';

/// code.html verse-index card: number badge, narrative title, summary.
/// Reused by search results, bookmarks and the journal.
class VerseTile extends StatelessWidget {
  const VerseTile({
    super.key,
    required this.verse,
    required this.onTap,
    this.showReference = false,
    this.trailing,
  });

  final LocalShloka verse;
  final VoidCallback? onTap;

  /// Badge shows `2.47` instead of `47` (outside the chapter's own index).
  final bool showReference;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final summary = verse.indexSummary ?? verse.englishMeaning;
    return SacredCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberBadge(
            showReference ? verse.reference : '${verse.verseNumber}',
            size: showReference ? 44 : 32,
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verse.indexTitle ?? 'Verse ${verse.reference}',
                  style: t.ui.copyWith(fontWeight: FontWeight.w600),
                ),
                if (summary != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.commentary.copyWith(
                      fontSize: 13,
                      height: 1.5,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right, size: 18, color: c.accent),
        ],
      ),
    );
  }
}
