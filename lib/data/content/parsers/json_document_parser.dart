import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../validators/json_schema_validator.dart';
import '../validators/validation_result.dart';

/// The result of parsing one content file: the typed model, or the reasons
/// it could not be produced. Never throws for bad input.
class ParseOutcome<T> {
  const ParseOutcome(this.value, this.issues);

  /// The parsed model, or null if any step failed.
  final T? value;

  /// Issues found while decoding, schema-validating and parsing.
  final List<ValidationIssue> issues;

  bool get isSuccess => value != null;
}

/// Shared steps for every content file:
/// UTF-8 text → (no BOM) → JSON → JSON Schema → typed model.
///
/// The model is built only from schema-valid documents, so parsing errors
/// after validation indicate a mismatch between schema and model, and are
/// reported as `PARSE_FAILED` rather than thrown.
ParseOutcome<T> parseJsonDocument<T>({
  required String text,
  required String fileName,
  required JsonSchemaValidator schema,
  required T Function(Map<String, dynamic> json) fromJson,
}) {
  final issues = <ValidationIssue>[];
  var body = text;
  if (body.startsWith('\uFEFF')) {
    issues.add(
      ValidationIssue(
        fileName: fileName,
        jsonPath: r'$',
        severity: ValidationSeverity.error,
        code: ValidationCode.invalidEncoding,
        message:
            'File starts with a UTF-8 byte order mark. Save it as UTF-8 '
            'without BOM.',
      ),
    );
    body = body.substring(1);
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException catch (e) {
    issues.add(
      ValidationIssue(
        fileName: fileName,
        jsonPath: r'$',
        severity: ValidationSeverity.error,
        code: ValidationCode.invalidJson,
        message:
            'Not valid JSON: ${e.message}'
            '${e.offset == null ? '' : ' (at character ${e.offset})'}.',
      ),
    );
    return ParseOutcome<T>(null, issues);
  }

  final schemaIssues = schema.validate(decoded, fileName: fileName);
  issues.addAll(schemaIssues);
  if (schemaIssues.isNotEmpty) return ParseOutcome<T>(null, issues);

  try {
    final value = fromJson((decoded! as Map).cast<String, dynamic>());
    return ParseOutcome<T>(issues.any((i) => i.isError) ? null : value, issues);
  } on CheckedFromJsonException catch (e) {
    issues.add(
      ValidationIssue(
        fileName: fileName,
        jsonPath: e.key == null ? r'$' : '\$.${e.key}',
        severity: ValidationSeverity.error,
        code: ValidationCode.parseFailed,
        message:
            'Could not build ${e.className ?? 'the model'}: '
            '${e.message ?? e.innerError}.',
      ),
    );
  } on Object catch (e) {
    issues.add(
      ValidationIssue(
        fileName: fileName,
        jsonPath: r'$',
        severity: ValidationSeverity.error,
        code: ValidationCode.parseFailed,
        message: 'Could not build the model: $e',
      ),
    );
  }
  return ParseOutcome<T>(null, issues);
}
