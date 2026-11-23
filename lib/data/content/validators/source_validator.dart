import '../models/source_content_model.dart';
import 'validation_result.dart';

/// Issues and the usable sources of `sources.json`.
class SourceValidationOutcome {
  const SourceValidationOutcome(this.issues, this.sourcesById);

  final List<ValidationIssue> issues;

  /// The first occurrence of each source id.
  final Map<String, SourceContentModel> sourcesById;
}

/// Level 2 checks for `sources.json`. Required names, the id format and the
/// URL format are enforced by the schema. This adds uniqueness and licence
/// checks. Source metadata is never invented or filled in.
class SourceValidator {
  const SourceValidator();

  SourceValidationOutcome validate({
    required String fileName,
    required SourcesFileModel model,
    required ValidationMode mode,
  }) {
    final issues = <ValidationIssue>[];
    final byId = <String, SourceContentModel>{};
    for (var i = 0; i < model.sources.length; i++) {
      final source = model.sources[i];
      final path = '\$.sources[$i]';
      if (byId.containsKey(source.id)) {
        issues.add(
          ValidationIssue(
            fileName: fileName,
            jsonPath: '$path.id',
            severity: ValidationSeverity.error,
            code: ValidationCode.duplicateSourceId,
            message: 'Source id "${source.id}" is used more than once.',
            scope: IssueScope.source,
            recordId: source.id,
          ),
        );
        continue;
      }
      byId[source.id] = source;
      if (!source.hasVerifiedLicense && mode != ValidationMode.structural) {
        issues.add(
          ValidationIssue(
            fileName: fileName,
            jsonPath: '$path.license',
            severity: ValidationSeverity.warning,
            code: ValidationCode.unverifiedSourceLicense,
            message:
                'Source "${source.id}" has no licence recorded. Content '
                'attributed to it cannot be approved.',
            scope: IssueScope.source,
            recordId: source.id,
          ),
        );
      }
    }
    return SourceValidationOutcome(issues, byId);
  }
}
