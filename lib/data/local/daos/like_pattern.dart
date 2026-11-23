/// Escape character used with every `LIKE` pattern built by [containsPattern].
const String likeEscapeChar = r'\';

/// A `LIKE` pattern matching any text that contains [term] literally.
/// `%`, `_` and `\` in [term] are escaped, so user input can't act as a
/// wildcard.
String containsPattern(String term) {
  final escaped = term
      .replaceAll(likeEscapeChar, '$likeEscapeChar$likeEscapeChar')
      .replaceAll('%', '$likeEscapeChar%')
      .replaceAll('_', '${likeEscapeChar}_');
  return '%$escaped%';
}
