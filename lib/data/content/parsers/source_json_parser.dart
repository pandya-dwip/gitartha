import '../models/source_content_model.dart';
import '../validators/json_schema_validator.dart';
import 'json_document_parser.dart';

/// Turns the text of `sources/sources.json` into a [SourcesFileModel], after
/// checking it against `sources.schema.json`.
class SourceJsonParser {
  const SourceJsonParser(this.schema);

  final JsonSchemaValidator schema;

  ParseOutcome<SourcesFileModel> parse(
    String text, {
    required String fileName,
  }) => parseJsonDocument(
    text: text,
    fileName: fileName,
    schema: schema,
    fromJson: SourcesFileModel.fromJson,
  );
}
