import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/sacred_widgets.dart';
import '../../../../data/local/daos/reading_progress_dao.dart';
import '../../../../data/local/database/app_database.dart';

/// code.html Chapter Library card.
class ChapterCard extends StatelessWidget {
  const ChapterCard({
    super.key,
    required this.chapter,
    required this.summary,
    required this.onTap,
  });

  final LocalChapter chapter;
  final ChapterProgressSummary? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final verses = summary?.totalShlokas ?? 0;
    final opened = summary?.opened ?? 0;
    final description = chapter.overview ?? chapter.summary;
    return SacredCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NumberBadge('${chapter.id}'),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chapter.sanskritName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.sanskrit.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                        Text(
                          '$verses Verses',
                          style: t.ui.copyWith(fontSize: 11, color: c.accent),
                        ),
                      ],
                    ),
                    Text(
                      chapter.englishName,
                      style: t.ui.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      chapter.hindiName,
                      style: t.sanskrit.copyWith(
                        fontSize: 13,
                        color: c.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
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
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          Divider(color: c.border.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  opened == 0
                      ? 'Not yet opened'
                      : '$opened of $verses verses opened',
                  style: t.commentary.copyWith(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: c.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
              Text(
                'Overview',
                style: t.ui.copyWith(
                  fontSize: 12,
                  color: c.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.arrow_forward, size: 14, color: c.accent),
            ],
          ),
        ],
      ),
    );
  }
}

/// code.html Home "The 18 Chapters" preview row.
class ChapterPreviewTile extends StatelessWidget {
  const ChapterPreviewTile({
    super.key,
    required this.chapter,
    required this.verses,
    required this.onTap,
  });

  final LocalChapter chapter;
  final int verses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return SacredCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          NumberBadge('${chapter.id}', size: 32),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.sanskritName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.sanskrit.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                Text(
                  '${chapter.englishName} • $verses Verses',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.ui.copyWith(fontSize: 11, color: c.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: c.accent),
        ],
      ),
    );
  }
}
