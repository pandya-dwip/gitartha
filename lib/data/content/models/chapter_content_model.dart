import 'package:json_annotation/json_annotation.dart';

import 'content_enums.dart';
import 'json_converters.dart';
import 'shloka_content_model.dart';

part 'chapter_content_model.g.dart';

/// One chapter file (`chapters/chapter_NN.json`): format version, chapter
/// metadata and all verses of the chapter.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  checked: true,
  disallowUnrecognizedKeys: true,
  explicitToJson: true,
)
class ChapterContentModel {
  const ChapterContentModel({
    required this.schemaVersion,
    required this.chapter,
    required this.verses,
  });

  factory ChapterContentModel.fromJson(Map<String, dynamic> json) =>
      _$ChapterContentModelFromJson(json);

  /// The only format version this code understands.
  static const String supportedSchemaVersion = '1.0.0';

  final String schemaVersion;
  final ChapterMetadataModel chapter;
  final List<ShlokaContentModel> verses;

  Map<String, dynamic> toJson() => _$ChapterContentModelToJson(this);
}

/// The `chapter` object of a chapter file. Empty text fields are `null`.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  checked: true,
  disallowUnrecognizedKeys: true,
)
@EmptyStringAsNullConverter()
class ChapterMetadataModel {
  const ChapterMetadataModel({
    required this.id,
    this.sanskritName,
    this.hindiName,
    this.englishName,
    this.introduction,
    this.overview,
    this.centralTheme,
    this.keyTopics = const [],
    this.summary,
    this.conclusion,
    this.reviewStatus = ReviewStatus.draft,
  });

  factory ChapterMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$ChapterMetadataModelFromJson(json);

  /// Chapter number, 1–18.
  final int id;
  final String? sanskritName;
  final String? hindiName;
  final String? englishName;
  final String? introduction;
  final String? overview;
  final String? centralTheme;
  final List<String> keyTopics;
  final String? summary;
  final String? conclusion;
  final ReviewStatus reviewStatus;

  /// Fields that must be filled before chapter metadata can be approved
  /// (content guidelines §12).
  static const List<String> fieldsRequiredForReview = [
    'sanskrit_name',
    'hindi_name',
    'english_name',
    'introduction',
    'overview',
    'central_theme',
    'key_topics',
    'summary',
    'conclusion',
  ];

  /// Required fields that are still empty.
  List<String> get missingRequiredFields {
    final values = <String, Object?>{
      'sanskrit_name': sanskritName,
      'hindi_name': hindiName,
      'english_name': englishName,
      'introduction': introduction,
      'overview': overview,
      'central_theme': centralTheme,
      'key_topics': keyTopics.isEmpty ? null : keyTopics,
      'summary': summary,
      'conclusion': conclusion,
    };
    return [
      for (final name in fieldsRequiredForReview)
        if (values[name] == null) name,
    ];
  }

  bool get isComplete => missingRequiredFields.isEmpty;

  /// The three names are required by the database (NOT NULL in Supabase).
  bool get hasAllNames =>
      sanskritName != null && hindiName != null && englishName != null;

  Map<String, dynamic> toJson() => _$ChapterMetadataModelToJson(this);
}
