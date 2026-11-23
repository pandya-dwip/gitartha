import 'package:json_annotation/json_annotation.dart';

import 'content_enums.dart';
import 'json_converters.dart';
import 'source_attribution_model.dart';

part 'shloka_content_model.g.dart';

/// One verse as stored in a chapter file. Empty text fields are `null`.
///
/// [hindiMeaning] (the translation) and [hindiMeaningNote] (an optional
/// wording note) are always separate.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  checked: true,
  disallowUnrecognizedKeys: true,
  explicitToJson: true,
)
@EmptyStringAsNullConverter()
class ShlokaContentModel {
  const ShlokaContentModel({
    required this.id,
    required this.verseNumber,
    required this.reference,
    this.indexTitle,
    this.indexSummary,
    this.sanskritText,
    this.transliteration,
    this.hindiMeaning,
    this.hindiMeaningNote,
    this.englishMeaning,
    this.context,
    this.lifeLesson,
    this.spiritualMeaning,
    this.reflectionQuestion,
    this.sourceAttributions = const [],
    this.reviewStatus = ReviewStatus.draft,
  });

  factory ShlokaContentModel.fromJson(Map<String, dynamic> json) =>
      _$ShlokaContentModelFromJson(json);

  /// Stable, human-readable content id, e.g. `chapter_01_verse_041`.
  final String id;
  final int verseNumber;

  /// `"<chapter>.<verse>"`, e.g. `1.41`.
  final String reference;

  final String? indexTitle;
  final String? indexSummary;
  final String? sanskritText;
  final String? transliteration;
  final String? hindiMeaning;
  final String? hindiMeaningNote;
  final String? englishMeaning;
  final String? context;
  final String? lifeLesson;
  final String? spiritualMeaning;
  final String? reflectionQuestion;
  final List<SourceAttributionModel> sourceAttributions;
  final ReviewStatus reviewStatus;

  /// Fields that must be filled before a verse can be reviewed or approved
  /// (content guidelines §12): every text field except the optional
  /// `hindi_meaning_note`.
  static const List<String> fieldsRequiredForReview = [
    'index_title',
    'index_summary',
    'sanskrit_text',
    'transliteration',
    'hindi_meaning',
    'english_meaning',
    'context',
    'life_lesson',
    'spiritual_meaning',
    'reflection_question',
  ];

  /// Sections that need a verified source before approval: the scripture
  /// and its translations (content guidelines §11).
  static const List<ContentSection> sectionsRequiringAttribution = [
    ContentSection.sanskritText,
    ContentSection.hindiMeaning,
    ContentSection.englishMeaning,
  ];

  /// All text fields by their JSON name, in reading order.
  Map<String, String?> get textFields => {
    'index_title': indexTitle,
    'index_summary': indexSummary,
    'sanskrit_text': sanskritText,
    'transliteration': transliteration,
    'hindi_meaning': hindiMeaning,
    'hindi_meaning_note': hindiMeaningNote,
    'english_meaning': englishMeaning,
    'context': context,
    'life_lesson': lifeLesson,
    'spiritual_meaning': spiritualMeaning,
    'reflection_question': reflectionQuestion,
  };

  /// The text of an attributable [section].
  String? textOf(ContentSection section) => textFields[section.jsonValue];

  /// Required fields that are still empty.
  List<String> get missingRequiredFields {
    final fields = textFields;
    return [
      for (final name in fieldsRequiredForReview)
        if (fields[name] == null) name,
    ];
  }

  /// Whether every required field is filled. This says nothing about
  /// whether the text has been verified.
  bool get isComplete => missingRequiredFields.isEmpty;

  Map<String, dynamic> toJson() => _$ShlokaContentModelToJson(this);
}
