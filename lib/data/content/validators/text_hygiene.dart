import 'validation_result.dart';

final RegExp _placeholder = RegExp(
  r'\b(TODO|TBD|FIXME|lorem ipsum)\b',
  caseSensitive: false,
);

/// How an incomplete record is reported in each mode: not per record in
/// `structural` mode, as a warning in `draft`, and as an error in `strict`.
ValidationSeverity? completenessSeverity(ValidationMode mode) => switch (mode) {
  ValidationMode.structural => null,
  ValidationMode.draft => ValidationSeverity.warning,
  ValidationMode.strict => ValidationSeverity.error,
};

/// Warnings for text that looks unfinished or uses Windows line endings.
List<ValidationIssue> textHygieneIssues({
  required String fileName,
  required String basePath,
  required Map<String, String?> fields,
  required IssueScope scope,
  String? recordId,
}) => [
  for (final MapEntry(key: field, value: text) in fields.entries)
    if (text != null) ...[
      if (_placeholder.hasMatch(text))
        ValidationIssue(
          fileName: fileName,
          jsonPath: '$basePath.$field',
          severity: ValidationSeverity.warning,
          code: ValidationCode.placeholderText,
          message: 'Looks like placeholder text (TODO/TBD/FIXME/lorem ipsum).',
          scope: scope,
          recordId: recordId,
        ),
      if (text.contains('\r'))
        ValidationIssue(
          fileName: fileName,
          jsonPath: '$basePath.$field',
          severity: ValidationSeverity.warning,
          code: ValidationCode.carriageReturn,
          message: r'Contains \r. Use \n line breaks only.',
          scope: scope,
          recordId: recordId,
        ),
    ],
];
