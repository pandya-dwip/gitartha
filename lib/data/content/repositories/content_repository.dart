import '../../local/database/app_database.dart';
import '../importers/content_import_service.dart';
import '../importers/import_result.dart';
import '../services/content_asset_loader.dart';
import '../services/content_validation_service.dart';
import '../validators/validation_result.dart';

export '../importers/import_result.dart'
    show ImportMode, ImportResult, ImportStatus;
export '../validators/validation_result.dart'
    show ValidationMode, ValidationResult, ValidationIssue, ValidationSeverity;

/// The entry point to the content pipeline for the rest of the app (and
/// future developer tooling): validate the content repository, or import it
/// into the local database.
///
/// Both operations are explicit. Nothing here runs automatically at app
/// startup, and nothing talks to Supabase.
class ContentRepository {
  ContentRepository({
    required ContentSource source,
    required AppDatabase database,
  }) : _validation = ContentValidationService(source),
       _source = source,
       _db = database;

  final ContentSource _source;
  final AppDatabase _db;
  final ContentValidationService _validation;

  /// Validates the repository (read-only).
  Future<ValidationResult> validate({
    ValidationMode mode = ValidationMode.draft,
    Iterable<int>? chapterIds,
  }) async =>
      (await _validation.validate(mode: mode, chapterIds: chapterIds)).result;

  /// Imports structurally valid content, complete or not. For local
  /// development and testing only; nothing is marked verified.
  Future<ImportResult> importDraft({Iterable<int>? chapterIds}) =>
      _import(ImportMode.draft, chapterIds);

  /// Imports only content that passes strict validation (complete,
  /// approved, properly sourced).
  Future<ImportResult> importApproved({Iterable<int>? chapterIds}) =>
      _import(ImportMode.approved, chapterIds);

  Future<ImportResult> _import(ImportMode mode, Iterable<int>? chapterIds) =>
      ContentImportService(
        source: _source,
        database: _db,
        validationService: _validation,
      ).importContent(mode: mode, chapterIds: chapterIds);
}
