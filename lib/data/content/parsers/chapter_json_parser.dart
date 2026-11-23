import '../models/chapter_content_model.dart';
import '../validators/json_schema_validator.dart';
import 'json_document_parser.dart';

/// Turns the text of a chapter file into a [ChapterContentModel], after
/// checking it against `chapter.schema.json`.
class ChapterJsonParser {
  const ChapterJsonParser(this.schema);

  final JsonSchemaValidator schema;

  ParseOutcome<ChapterContentModel> parse(
    String text, {
    required String fileName,
  }) => parseJsonDocument(
    text: text,
    fileName: fileName,
    schema: schema,
    fromJson: ChapterContentModel.fromJson,
  );
}
