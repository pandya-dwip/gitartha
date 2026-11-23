// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shloka_content_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShlokaContentModel _$ShlokaContentModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ShlokaContentModel',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      allowedKeys: const [
        'id',
        'verse_number',
        'reference',
        'index_title',
        'index_summary',
        'sanskrit_text',
        'transliteration',
        'hindi_meaning',
        'hindi_meaning_note',
        'english_meaning',
        'context',
        'life_lesson',
        'spiritual_meaning',
        'reflection_question',
        'source_attributions',
        'review_status',
      ],
    );
    final val = ShlokaContentModel(
      id: $checkedConvert('id', (v) => v as String),
      verseNumber: $checkedConvert('verse_number', (v) => (v as num).toInt()),
      reference: $checkedConvert('reference', (v) => v as String),
      indexTitle: $checkedConvert(
        'index_title',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      indexSummary: $checkedConvert(
        'index_summary',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      sanskritText: $checkedConvert(
        'sanskrit_text',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      transliteration: $checkedConvert(
        'transliteration',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      hindiMeaning: $checkedConvert(
        'hindi_meaning',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      hindiMeaningNote: $checkedConvert(
        'hindi_meaning_note',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      englishMeaning: $checkedConvert(
        'english_meaning',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      context: $checkedConvert(
        'context',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      lifeLesson: $checkedConvert(
        'life_lesson',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      spiritualMeaning: $checkedConvert(
        'spiritual_meaning',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      reflectionQuestion: $checkedConvert(
        'reflection_question',
        (v) => _$JsonConverterFromJson<String, String?>(
          v,
          const EmptyStringAsNullConverter().fromJson,
        ),
      ),
      sourceAttributions: $checkedConvert(
        'source_attributions',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => SourceAttributionModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            const [],
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
    'verseNumber': 'verse_number',
    'indexTitle': 'index_title',
    'indexSummary': 'index_summary',
    'sanskritText': 'sanskrit_text',
    'hindiMeaning': 'hindi_meaning',
    'hindiMeaningNote': 'hindi_meaning_note',
    'englishMeaning': 'english_meaning',
    'lifeLesson': 'life_lesson',
    'spiritualMeaning': 'spiritual_meaning',
    'reflectionQuestion': 'reflection_question',
    'sourceAttributions': 'source_attributions',
    'reviewStatus': 'review_status',
  },
);

Map<String, dynamic> _$ShlokaContentModelToJson(
  ShlokaContentModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'verse_number': instance.verseNumber,
  'reference': instance.reference,
  'index_title': const EmptyStringAsNullConverter().toJson(instance.indexTitle),
  'index_summary': const EmptyStringAsNullConverter().toJson(
    instance.indexSummary,
  ),
  'sanskrit_text': const EmptyStringAsNullConverter().toJson(
    instance.sanskritText,
  ),
  'transliteration': const EmptyStringAsNullConverter().toJson(
    instance.transliteration,
  ),
  'hindi_meaning': const EmptyStringAsNullConverter().toJson(
    instance.hindiMeaning,
  ),
  'hindi_meaning_note': const EmptyStringAsNullConverter().toJson(
    instance.hindiMeaningNote,
  ),
  'english_meaning': const EmptyStringAsNullConverter().toJson(
    instance.englishMeaning,
  ),
  'context': const EmptyStringAsNullConverter().toJson(instance.context),
  'life_lesson': const EmptyStringAsNullConverter().toJson(instance.lifeLesson),
  'spiritual_meaning': const EmptyStringAsNullConverter().toJson(
    instance.spiritualMeaning,
  ),
  'reflection_question': const EmptyStringAsNullConverter().toJson(
    instance.reflectionQuestion,
  ),
  'source_attributions': instance.sourceAttributions
      .map((e) => e.toJson())
      .toList(),
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
