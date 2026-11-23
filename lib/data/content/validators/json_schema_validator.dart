import 'dart:convert';

import 'package:json_schema/json_schema.dart';

import 'validation_result.dart';

/// Level 1: validates a decoded JSON document against one of the
/// repository's JSON Schemas (Draft 2020-12), using the `json_schema`
/// package's full implementation.
///
/// The schema files are used exactly as written; they are never rewritten
/// to suit the validator. Errors are reported with a JSONPath-style location
/// and, where the location identifies a well-known field, a specific stable
/// code (for example `INVALID_CHAPTER_ID`) instead of the generic
/// `SCHEMA_VALIDATION_FAILED`.
class JsonSchemaValidator {
  JsonSchemaValidator._(this._schema, this.schemaName);

  /// Compiles [schemaJson] (the text of a schema file). Throws
  /// [FormatException] if it is not valid JSON or not a usable schema.
  factory JsonSchemaValidator.fromSchemaText(
    String schemaJson, {
    required String schemaName,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(schemaJson);
    } on FormatException catch (e) {
      throw FormatException('$schemaName is not valid JSON: ${e.message}');
    }
    try {
      return JsonSchemaValidator._(JsonSchema.create(decoded!), schemaName);
    } on Object catch (e) {
      throw FormatException('$schemaName is not a usable JSON Schema: $e');
    }
  }

  final JsonSchema _schema;
  final String schemaName;

  /// The draft the schema declares (`$schema`).
  String get draft => _schema.schemaVersion.toString();

  /// Validates [document]. Returns one issue per distinct problem (empty if
  /// valid). All issues are errors of [IssueScope.file].
  List<ValidationIssue> validate(Object? document, {required String fileName}) {
    final results = _schema.validate(document);
    if (results.isValid) return const [];
    final seen = <String>{};
    final issues = <ValidationIssue>[];
    for (final error in results.errors) {
      final path = jsonPointerToPath(error.instancePath);
      final message = _describe(error.message);
      // The package reports some failures at both the parent and the child
      // location. Keep one per distinct message.
      if (!seen.add(message)) continue;
      issues.add(
        ValidationIssue(
          fileName: fileName,
          jsonPath: path,
          severity: ValidationSeverity.error,
          code: codeForPath(path),
          message: message,
        ),
      );
    }
    return issues;
  }

  /// `/verses/0/hindi_meaning` → `$.verses[0].hindi_meaning`.
  static String jsonPointerToPath(String pointer) {
    if (pointer.isEmpty || pointer == '/') return r'$';
    final b = StringBuffer(r'$');
    for (final raw in pointer.split('/').skip(1)) {
      final segment = raw.replaceAll('~1', '/').replaceAll('~0', '~');
      if (int.tryParse(segment) != null) {
        b.write('[$segment]');
      } else {
        b.write('.$segment');
      }
    }
    return b.toString();
  }

  static final List<(RegExp, String)> _pathCodes = [
    (RegExp(r'^\$\.chapter\.id$'), ValidationCode.invalidChapterId),
    (
      RegExp(r'^\$\.verses\[\d+\]\.verse_number$'),
      ValidationCode.invalidVerseNumber,
    ),
    (
      RegExp(r'^\$\.verses\[\d+\]\.reference$'),
      ValidationCode.invalidReference,
    ),
    (RegExp(r'^\$\.verses\[\d+\]\.id$'), ValidationCode.invalidShlokaId),
    (
      RegExp(
        r'^\$\.verses\[\d+\]\.source_attributions\[\d+\]\.content_section$',
      ),
      ValidationCode.invalidContentSection,
    ),
    (RegExp(r'^\$\.sources\[\d+\]\.name$'), ValidationCode.missingSourceName),
  ];

  /// The specific code for an error at [path], or
  /// [ValidationCode.schemaValidationFailed].
  static String codeForPath(String path) {
    for (final (pattern, code) in _pathCodes) {
      if (pattern.hasMatch(path)) return code;
    }
    return ValidationCode.schemaValidationFailed;
  }

  /// Rewrites the package's terse messages into readable ones.
  static String _describe(String raw) {
    final required = RegExp(r'^required prop missing: (\S+)').firstMatch(raw);
    if (required != null) {
      return 'Missing required property "${required.group(1)}".';
    }
    final type = RegExp(
      r'^type: wanted \[(.+?)\] got (.*)$',
      dotAll: true,
    ).firstMatch(raw);
    if (type != null) {
      return 'Expected a ${type.group(1)} value, found ${_preview(type.group(2)!)}.';
    }
    final extra = RegExp(
      r'unallowed additional property (\S+)',
    ).firstMatch(raw);
    if (extra != null) {
      return 'Unexpected property "${extra.group(1)}" (not allowed by the schema).';
    }
    if (raw.startsWith('enum violated')) {
      return 'Value ${_preview(raw.substring('enum violated'.length).trim())} '
          'is not one of the allowed values.';
    }
    if (raw.startsWith('uniqueItems violated')) {
      return 'Array items must be unique.';
    }
    if (raw.startsWith('pattern violated')) {
      final value = RegExp(
        r'^pattern violated \((.*) vs RegExp',
        dotAll: true,
      ).firstMatch(raw)?.group(1);
      return 'Value ${value == null ? '' : '${_preview(value)} '}does not have '
          'the required format (no leading/trailing whitespace; ids and '
          'references must follow the content conventions).';
    }
    if (raw.startsWith('const violated')) {
      return 'Value must be exactly ${raw.substring('const violated'.length).trim()}.';
    }
    return _preview(raw, max: 200);
  }

  static String _preview(String s, {int max = 60}) {
    final single = s.replaceAll('\n', r'\n');
    return single.length <= max
        ? '"$single"'
        : '"${single.substring(0, max)}…"';
  }
}
