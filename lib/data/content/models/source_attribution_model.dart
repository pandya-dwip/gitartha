import 'package:json_annotation/json_annotation.dart';

import 'content_enums.dart';

part 'source_attribution_model.g.dart';

/// One entry of a verse's `source_attributions`: which source a section of
/// the verse came from.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  checked: true,
  disallowUnrecognizedKeys: true,
)
class SourceAttributionModel {
  const SourceAttributionModel({
    required this.sourceId,
    required this.contentSection,
  });

  factory SourceAttributionModel.fromJson(Map<String, dynamic> json) =>
      _$SourceAttributionModelFromJson(json);

  /// Stable snake_case id of an entry in `sources/sources.json`.
  final String sourceId;
  final ContentSection contentSection;

  Map<String, dynamic> toJson() => _$SourceAttributionModelToJson(this);

  @override
  bool operator ==(Object other) =>
      other is SourceAttributionModel &&
      other.sourceId == sourceId &&
      other.contentSection == contentSection;

  @override
  int get hashCode => Object.hash(sourceId, contentSection);

  @override
  String toString() => '$sourceId:${contentSection.jsonValue}';
}
