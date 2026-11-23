// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter_content_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChapterContentModel _$ChapterContentModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ChapterContentModel', json, ($checkedConvert) {
  $checkKeys(json, allowedKeys: const ['schema_version', 'chapter', 'verses']);
  final val = ChapterContentModel(
    schemaVersion: $checkedConvert('schema_version', (v) => v as String),
    chapter: $checkedConvert(
      'chapter',
      (v) => ChapterMetadataModel.fromJson(v as Map<String, dynamic>),
    ),
    verses: $checkedConvert(
      'verses',
      (v) => (v as List<dynamic>)
          .map((e) => ShlokaContentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'schemaVersion': 'schema_version'});

Map<String, dynamic> _$ChapterContentModelToJson(
  ChapterContentModel instance,
) => <String, dynamic>{
  'schema_version': instance.schemaVersion,
  'chapter': instance.chapter.toJson(),
  'verses': instance.verses.map((e) => e.toJson()).toList(),
};

ChapterMetadataModel _$ChapterMetadataModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ChapterMetadataModel',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'id',
        'sanskrit_name',
        'hindi_name',
        'english_name',
        'introduction',
        'overview',
        'central_theme',
        'key_topics',
        'summary',
        'conclusion',
        'review_status',
      ],
    );
    final val = ChapterMetadataModel(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      sanskritName: $checkedConvert(
        'sanskrit_name',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      hindiName: $checkedConvert(
        'hindi_name',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      englishName: $checkedConvert(
        'english_name',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      introduction: $checkedConvert(
        'introduction',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      overview: $checkedConvert(
        'overview',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      centralTheme: $checkedConvert(
        'central_theme',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      keyTopics: $checkedConvert(
        'key_topics',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      ),
      summary: $checkedConvert(
        'summary',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      conclusion: $checkedConvert(
        'conclusion',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      reviewStatus: $checkedConvert(
        'review_status',
        (v) =>
            $enumDecodeNullable(_$ReviewStatusEnumMap, v) ?? ReviewStatus.draft,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'sanskritName': 'sanskrit_name',
    'hindiName': 'hindi_name',
    'englishName': 'english_name',
    'centralTheme': 'central_theme',
    'keyTopics': 'key_topics',
    'reviewStatus': 'review_status',
  },
);

Map<String, dynamic> _$ChapterMetadataModelToJson(
  ChapterMetadataModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'sanskrit_name': const EmptyStringAsNullConverter().toJson(
    instance.sanskritName,
  ),
  'hindi_name': const EmptyStringAsNullConverter().toJson(instance.hindiName),
  'english_name': const EmptyStringAsNullConverter().toJson(
    instance.englishName,
  ),
  'introduction': const EmptyStringAsNullConverter().toJson(
    instance.introduction,
  ),
  'overview': const EmptyStringAsNullConverter().toJson(instance.overview),
  'central_theme': const EmptyStringAsNullConverter().toJson(
    instance.centralTheme,
  ),
  'key_topics': instance.keyTopics,
  'summary': const EmptyStringAsNullConverter().toJson(instance.summary),
  'conclusion': const EmptyStringAsNullConverter().toJson(instance.conclusion),
  'review_status': _$ReviewStatusEnumMap[instance.reviewStatus]!,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$ReviewStatusEnumMap = {
  ReviewStatus.draft: 'draft',
  ReviewStatus.inReview: 'in_review',
  ReviewStatus.approved: 'approved',
};
