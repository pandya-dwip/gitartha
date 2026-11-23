// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_content_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SourcesFileModel _$SourcesFileModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SourcesFileModel', json, ($checkedConvert) {
      $checkKeys(json, allowedKeys: const ['sources']);
      final val = SourcesFileModel(
        sources: $checkedConvert(
          'sources',
          (v) => (v as List<dynamic>)
              .map(
                (e) => SourceContentModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SourcesFileModelToJson(SourcesFileModel instance) =>
    <String, dynamic>{
      'sources': instance.sources.map((e) => e.toJson()).toList(),
    };

SourceContentModel _$SourceContentModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SourceContentModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        allowedKeys: const [
          'id',
          'name',
          'author',
          'source_url',
          'license',
          'attribution',
        ],
      );
      final val = SourceContentModel(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        author: $checkedConvert(
          'author',
          (v) => _$JsonConverterFromJson<String, String?>(
            v,
            const EmptyStringAsNullConverter().fromJson,
          ),
        ),
        sourceUrl: $checkedConvert(
          'source_url',
          (v) => _$JsonConverterFromJson<String, String?>(
            v,
            const EmptyStringAsNullConverter().fromJson,
          ),
        ),
        license: $checkedConvert(
          'license',
          (v) => _$JsonConverterFromJson<String, String?>(
            v,
            const EmptyStringAsNullConverter().fromJson,
          ),
        ),
        attribution: $checkedConvert(
          'attribution',
          (v) => _$JsonConverterFromJson<String, String?>(
            v,
            const EmptyStringAsNullConverter().fromJson,
          ),
        ),
      );
      return val;
    }, fieldKeyMap: const {'sourceUrl': 'source_url'});

Map<String, dynamic> _$SourceContentModelToJson(
  SourceContentModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'author': const EmptyStringAsNullConverter().toJson(instance.author),
  'source_url': const EmptyStringAsNullConverter().toJson(instance.sourceUrl),
  'license': const EmptyStringAsNullConverter().toJson(instance.license),
  'attribution': const EmptyStringAsNullConverter().toJson(
    instance.attribution,
  ),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);
