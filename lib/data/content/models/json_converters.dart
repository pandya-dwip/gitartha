import 'package:json_annotation/json_annotation.dart';

/// The content repository writes "not written yet" as `""`. Dart code (and
/// the database) uses `null` for that, so this converter maps `""` to null
/// when reading and null back to `""` when writing. The file format
/// round-trips unchanged.
class EmptyStringAsNullConverter implements JsonConverter<String?, String> {
  const EmptyStringAsNullConverter();

  @override
  String? fromJson(String json) => json.isEmpty ? null : json;

  @override
  String toJson(String? object) => object ?? '';
}
