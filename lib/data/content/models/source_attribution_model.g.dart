// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_attribution_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SourceAttributionModel _$SourceAttributionModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SourceAttributionModel',
  json,
  ($checkedConvert) {
    $checkKeys(json, allowedKeys: const ['source_id', 'content_section']);
    final val = SourceAttributionModel(
      sourceId: $checkedConvert('source_id', (v) => v as String),
      contentSection: $checkedConvert(
        'content_section',
        (v) => $enumDecode(_$ContentSectionEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'sourceId': 'source_id',
    'contentSection': 'content_section',
  },
);

Map<String, dynamic> _$SourceAttributionModelToJson(
  SourceAttributionModel instance,
) => <String, dynamic>{
  'source_id': instance.sourceId,
  'content_section': _$ContentSectionEnumMap[instance.contentSection]!,
};

const _$ContentSectionEnumMap = {
  ContentSection.sanskritText: 'sanskrit_text',
  ContentSection.transliteration: 'transliteration',
  ContentSection.hindiMeaning: 'hindi_meaning',
  ContentSection.hindiMeaningNote: 'hindi_meaning_note',
  ContentSection.englishMeaning: 'english_meaning',
  ContentSection.context: 'context',
  ContentSection.lifeLesson: 'life_lesson',
  ContentSection.spiritualMeaning: 'spiritual_meaning',
  ContentSection.reflectionQuestion: 'reflection_question',
};
