import 'package:json_annotation/json_annotation.dart';

import 'json_converters.dart';

part 'source_content_model.g.dart';

/// `sources/sources.json`.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  checked: true,
  disallowUnrecognizedKeys: true,
  explicitToJson: true,
)
class SourcesFileModel {
  const SourcesFileModel({required this.sources});

  factory SourcesFileModel.fromJson(Map<String, dynamic> json) =>
      _$SourcesFileModelFromJson(json);

  final List<SourceContentModel> sources;

  Map<String, dynamic> toJson() => _$SourcesFileModelToJson(this);
}

/// A verified content source. Empty text fields are `null`.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  checked: true,
  disallowUnrecognizedKeys: true,
)
@EmptyStringAsNullConverter()
class SourceContentModel {
  const SourceContentModel({
    required this.id,
    required this.name,
    this.author,
    this.sourceUrl,
    this.license,
    this.attribution,
  });

  factory SourceContentModel.fromJson(Map<String, dynamic> json) =>
      _$SourceContentModelFromJson(json);

  /// Stable snake_case id, referenced by verse attributions.
  final String id;
  final String name;
  final String? author;
  final String? sourceUrl;

  /// Licence or permission terms. `null` means not yet verified, and content
  /// attributed to the source cannot be approved.
  final String? license;
  final String? attribution;

  bool get hasVerifiedLicense => license != null;

  Map<String, dynamic> toJson() => _$SourceContentModelToJson(this);
}
