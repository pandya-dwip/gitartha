// Validates the Bhagavad Gita content repository (assets/data/bhagavad_gita).
//
// Usage, from the project root:
//
//   dart run tool/validate_gita_content.dart                 # all chapters, draft mode
//   dart run tool/validate_gita_content.dart --mode=strict   # publishing rules
//   dart run tool/validate_gita_content.dart --chapter=1 --verbose
//   dart run tool/validate_gita_content.dart --json          # machine-readable
//
// Options:
//   --mode=structural|draft|strict   validation mode (default: draft)
//   --chapter=N                      only chapter N (repeatable)
//   --all                            all 18 chapters (the default)
//   --verbose                        also list informational messages
//   --json                           print the result as JSON
//   --output=FILE                    also write the JSON result to FILE (outside
//                                    the content repository). Use this for
//                                    tooling: `dart run` itself may print
//                                    "Running build hooks..." to stdout.
//   --root=PATH                      repository root (default: assets/data/bhagavad_gita)
//
// Exit codes: 0 = valid in the chosen mode, 1 = validation errors,
//             2 = bad arguments or the schemas could not be loaded.
//
// Read-only: never modifies JSON files, never imports into any database,
// never contacts Supabase. The checks themselves live in
// lib/data/content/ and are shared with the app's import pipeline.

import 'dart:convert';
import 'dart:io';

import 'package:gitartha/data/content/content_constants.dart';
import 'package:gitartha/data/content/services/content_validation_service.dart';
import 'package:gitartha/data/content/services/file_system_content_source.dart';
import 'package:gitartha/data/content/validators/validation_result.dart';

Future<void> main(List<String> args) async {
  final ValidationMode mode;
  final Set<int> chapters = {};
  var verbose = false;
  var asJson = false;
  var root = GitaContent.rootPath;
  String? outputPath;
  var modeName = 'draft';

  for (final arg in args) {
    if (arg.startsWith('--mode=')) {
      modeName = arg.substring(7);
    } else if (arg.startsWith('--chapter=')) {
      final n = int.tryParse(arg.substring(10));
      if (n == null || n < 1 || n > GitaContent.chapterCount) {
        return _usage('--chapter must be a number from 1 to 18: $arg');
      }
      chapters.add(n);
    } else if (arg == '--all') {
      chapters.clear();
    } else if (arg == '--verbose') {
      verbose = true;
    } else if (arg == '--json') {
      asJson = true;
    } else if (arg.startsWith('--output=')) {
      outputPath = arg.substring(9);
    } else if (arg.startsWith('--root=')) {
      root = arg.substring(7);
    } else if (arg == '--help' || arg == '-h') {
      return _usage(null);
    } else {
      return _usage('Unknown argument: $arg');
    }
  }
  try {
    mode = ValidationMode.parse(modeName);
  } on FormatException catch (e) {
    return _usage(e.message);
  }

  if (outputPath != null && _isInside(outputPath, root)) {
    return _usage('--output must not point inside the content repository.');
  }

  final report = await ContentValidationService(
    FileSystemContentSource(root),
  ).validate(mode: mode, chapterIds: chapters.isEmpty ? null : chapters);
  final result = report.result;

  if (outputPath != null) {
    File(outputPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(result.toJson()),
    );
  }

  if (asJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(result.toJson()));
  } else {
    stdout
      ..writeln(_chapterTable(report))
      ..write(result.toReport(includeInfo: verbose));
  }

  final schemaFailure = result.errors.any(
    (e) =>
        e.code == ValidationCode.assetLoadFailed &&
        e.fileName.endsWith('.schema.json'),
  );
  exitCode = schemaFailure ? 2 : (result.isValid ? 0 : 1);
}

/// Whether [file] lies inside directory [dir]. Compares normalized absolute
/// file URIs (forward slashes, case-insensitive for Windows drives).
bool _isInside(String file, String dir) {
  final f = File(file).absolute.uri.path.toLowerCase();
  final d = Directory(dir).absolute.uri.path.toLowerCase();
  return f.startsWith(d.endsWith('/') ? d : '$d/');
}

String _chapterTable(ContentValidationReport report) {
  final b = StringBuffer()
    ..writeln(
      'Chapter  File              Verses    Complete  Approved  '
      'Publication-ready',
    );
  for (final c in report.chapters) {
    final id = c.expectedChapterId.toString().padLeft(5);
    if (c.model == null) {
      b.writeln(
        '$id    ${c.fileName.padRight(18)}(could not be parsed — see errors)',
      );
      continue;
    }
    final expected = GitaContent.expectedVerseCounts[c.expectedChapterId];
    b.writeln(
      '$id    ${c.fileName.padRight(18)}'
      '${'${c.verses.length}/$expected'.padRight(10)}'
      '${c.verses.where((v) => v.isComplete).length.toString().padRight(10)}'
      '${c.verses.where((v) => v.isApproved).length.toString().padRight(10)}'
      '${c.isPublicationReady ? 'yes' : 'no'}',
    );
  }
  return b.toString();
}

void _usage(String? problem) {
  if (problem != null) stderr.writeln(problem);
  stderr.writeln(
    'Usage: dart run tool/validate_gita_content.dart '
    '[--mode=structural|draft|strict] [--chapter=N]... [--all] [--verbose] '
    '[--json] [--output=FILE] [--root=PATH]',
  );
  exitCode = problem == null ? 0 : 2;
}
