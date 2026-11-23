import 'package:json_annotation/json_annotation.dart';

/// Editorial review state recorded in the content repository
/// (`review_status`). People set it; nothing derives it from the text.
///
/// Only [approved] content may be imported in approved mode. The presence
/// of text is never treated as proof that it was verified.
@JsonEnum()
enum ReviewStatus {
  @JsonValue('draft')
  draft('draft'),
  @JsonValue('in_review')
  inReview('in_review'),
  @JsonValue('approved')
  approved('approved');

  const ReviewStatus(this.jsonValue);

  final String jsonValue;
}

/// A verse field that a source can be attributed to. The values match the
/// JSON Schema enum, Supabase's `shloka_source_attributions` CHECK and the
/// local attribution table.
@JsonEnum()
enum ContentSection {
  @JsonValue('sanskrit_text')
  sanskritText('sanskrit_text'),
  @JsonValue('transliteration')
  transliteration('transliteration'),
  @JsonValue('hindi_meaning')
  hindiMeaning('hindi_meaning'),
  @JsonValue('hindi_meaning_note')
  hindiMeaningNote('hindi_meaning_note'),
  @JsonValue('english_meaning')
  englishMeaning('english_meaning'),
  @JsonValue('context')
  context('context'),
  @JsonValue('life_lesson')
  lifeLesson('life_lesson'),
  @JsonValue('spiritual_meaning')
  spiritualMeaning('spiritual_meaning'),
  @JsonValue('reflection_question')
  reflectionQuestion('reflection_question');

  const ContentSection(this.jsonValue);

  /// The JSON / database value, which is also the verse field name.
  final String jsonValue;
}
