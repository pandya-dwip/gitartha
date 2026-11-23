import 'dart:convert';
import 'dart:io';

import 'package:gitartha/core/utils/uuid.dart';
import 'package:gitartha/data/content/content_constants.dart';
import 'package:gitartha/data/content/importers/import_result.dart';
import 'package:gitartha/data/content/publishing/publisher_access.dart';
import 'package:gitartha/data/content/publishing/publishing_executor.dart';
import 'package:gitartha/data/content/publishing/publishing_models.dart';
import 'package:gitartha/data/content/publishing/publishing_planner.dart';
import 'package:gitartha/data/content/publishing/publishing_report_formatter.dart';
import 'package:gitartha/data/content/publishing/publishing_result.dart';
import 'package:gitartha/data/content/publishing/remote_content_store.dart';
import 'package:gitartha/data/content/selection/content_selection.dart';
import 'package:gitartha/data/content/services/content_asset_loader.dart';
import 'package:gitartha/data/content/services/content_validation_service.dart';
import 'package:gitartha/data/content/validators/validation_result.dart';

import 'publishing_config.dart';
import 'terminal.dart';

enum PublishMode { validateOnly, dryRun, confirm }

/// Exit codes of `tool/publish_gita_content.dart`.
abstract final class PublishExit {
  static const int ok = 0;

  /// Blocking validation errors, plan errors, or the publish was cancelled.
  static const int content = 1;

  /// Bad arguments or configuration.
  static const int usage = 2;

  /// Sign-in failed or publishing permission denied.
  static const int access = 3;

  /// Remote problem: schema mismatch, failed or partial publish.
  static const int remote = 4;
}

class PublishOptions {
  const PublishOptions({
    required this.scope,
    required this.mode,
    this.saveReport = false,
    this.envFile = '.env',
  });

  final PublishingScope scope;
  final PublishMode mode;
  final bool saveReport;
  final String envFile;

  static const String usage = '''
Usage: dart run tool/publish_gita_content.dart (--all | --chapter=N [--verse=N])
                                               [--validate-only | --dry-run | --confirm]
                                               [--save-report] [--env-file=PATH]

  --all              every chapter
  --chapter=N        one chapter (1-18)
  --verse=N          with --chapter: only this verse
  --validate-only    validate with the publishing (strict) rules; no sign-in (default)
  --dry-run          sign in, compare with Supabase and show the plan; writes nothing
  --confirm          as --dry-run, then publish after you type "publish"
  --save-report      write the JSON report to reports/content-publishing/
  --env-file=PATH    where SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY are read (default .env)
  --help             this text

Credentials are never accepted as arguments: you are asked for your email,
and for your password without it being shown.''';

  /// Parses [args]. Throws [FormatException] with a user-facing message.
  static PublishOptions parse(List<String> args) {
    int? chapter;
    int? verse;
    var all = false;
    final modes = <PublishMode>{};
    var save = false;
    var envFile = '.env';

    int number(String arg, String name, int min, int max) {
      final n = int.tryParse(arg.substring(name.length + 3));
      if (n == null || n < min || n > max) {
        throw FormatException(
          '--$name must be a number from $min to $max: $arg',
        );
      }
      return n;
    }

    for (final arg in args) {
      if (arg == '--all') {
        all = true;
      } else if (arg.startsWith('--chapter=')) {
        chapter = number(arg, 'chapter', 1, GitaContent.chapterCount);
      } else if (arg.startsWith('--verse=')) {
        verse = number(arg, 'verse', 1, 200);
      } else if (arg == '--validate-only') {
        modes.add(PublishMode.validateOnly);
      } else if (arg == '--dry-run') {
        modes.add(PublishMode.dryRun);
      } else if (arg == '--confirm') {
        modes.add(PublishMode.confirm);
      } else if (arg == '--save-report') {
        save = true;
      } else if (arg.startsWith('--env-file=')) {
        envFile = arg.substring('--env-file='.length);
      } else if (_looksLikeCredential(arg)) {
        throw const FormatException(
          'Credentials are never accepted as arguments. You will be asked for '
          'them.',
        );
      } else {
        throw FormatException('Unknown argument: $arg');
      }
    }

    if (all && chapter != null) {
      throw const FormatException(
        '--all and --chapter are mutually exclusive.',
      );
    }
    if (!all && chapter == null) {
      throw const FormatException('Choose a scope: --all or --chapter=N.');
    }
    if (verse != null && chapter == null) {
      throw const FormatException('--verse requires --chapter.');
    }
    if (chapter != null && verse != null) {
      final max = GitaContent.expectedVerseCounts[chapter]!;
      if (verse > max) {
        throw FormatException(
          '--verse=$verse is beyond the $max verses of chapter $chapter.',
        );
      }
    }
    if (modes.length > 1) {
      throw const FormatException(
        'Use only one of --validate-only, --dry-run and --confirm.',
      );
    }
    return PublishOptions(
      scope: all
          ? const PublishingScope.all()
          : PublishingScope.chapter(chapter!, verseNumber: verse),
      mode: modes.isEmpty ? PublishMode.validateOnly : modes.single,
      saveReport: save,
      envFile: envFile,
    );
  }

  static bool _looksLikeCredential(String arg) {
    final lower = arg.toLowerCase();
    return lower.startsWith('--password') ||
        lower.startsWith('--email') ||
        lower.startsWith('--token') ||
        lower.startsWith('--key');
  }
}

/// Orchestrates one publishing run:
///
/// validate (strict) → [validate-only stops here] → configuration →
/// sign-in → membership check → remote schema check → plan → preview →
/// [dry run stops here] → typed confirmation → ordered writes → report.
class PublishCommand {
  PublishCommand({
    required this.terminal,
    required this.content,
    required this.storeFactory,
    PublishingConfig Function(String envFile)? configLoader,
    this.reportDirectory = 'reports/content-publishing',
    DateTime Function()? clock,
  }) : _loadConfig = configLoader ?? ((f) => PublishingConfig.load(envFile: f)),
       _now = clock ?? (() => DateTime.now().toUtc());

  final PublisherTerminal terminal;
  final ContentSource content;
  final RemoteContentStore Function(PublishingConfig config) storeFactory;
  final PublishingConfig Function(String envFile) _loadConfig;
  final String reportDirectory;
  final DateTime Function() _now;

  /// The last run's result (for tests and tooling).
  PublishingResult? lastResult;

  Future<int> run(PublishOptions options) async {
    final scope = options.scope;
    final dryRun = options.mode != PublishMode.confirm;
    final result = PublishingResult(
      operationId: generateUuidV4(),
      target: '(not contacted)',
      scope: scope,
      dryRun: dryRun,
      startedAt: _now(),
    );
    lastResult = result;
    final out = terminal.write;

    // 1. Validation (always; no network).
    final report = await ContentValidationService(
      content,
    ).validate(mode: ValidationMode.strict);
    result.validation = report.result;
    final blocking = blockingIssues(report.result, scope);
    final selection = const ContentSelector().select(
      report,
      mode: ImportMode.approved,
      chapterIds: scope.chapterIds,
      verseNumber: scope.verseNumber,
    );
    result.rejectedByValidation = selection.rejected;
    final publishable = selection.chapters.fold<int>(
      0,
      (n, c) => n + c.verses.length,
    );

    if (options.mode == PublishMode.validateOnly) {
      out(
        PublishingReportFormatter.header(
          target: '(not contacted: --validate-only)',
          scope: scope,
          mode: 'VALIDATE ONLY',
        ),
      );
      out(
        PublishingReportFormatter.validation(
          report.result,
          blocking: blocking,
          publishableVerses: publishable,
        ),
      );
      if (blocking.isEmpty && publishable == 0) {
        out(
          '\nNothing is publishable in this scope yet: only complete, '
          'approved and sourced verses are published.\n',
        );
      }
      return _finish(
        result,
        options,
        blocking.isEmpty ? PublishExit.ok : PublishExit.content,
        stage: blocking.isEmpty ? null : PublishingStage.validation,
        message: blocking.isEmpty
            ? null
            : 'Validation found ${blocking.length} blocking error(s).',
        dryRunValidation: true,
      );
    }

    // 2. Configuration.
    final PublishingConfig config;
    try {
      config = _loadConfig(options.envFile);
    } on PublishingConfigException catch (e) {
      out('Configuration error: ${e.message}\n');
      return _finish(
        result,
        options,
        PublishExit.usage,
        stage: PublishingStage.configuration,
        message: e.message,
      );
    }
    final withTarget =
        PublishingResult(
            operationId: result.operationId,
            target: config.host,
            scope: scope,
            dryRun: dryRun,
            startedAt: result.startedAt,
          )
          ..validation = result.validation
          ..rejectedByValidation = result.rejectedByValidation;
    lastResult = withTarget;

    out(
      PublishingReportFormatter.header(
        target: 'Supabase (${config.host}) using ${config.keyVariable}',
        scope: scope,
        mode: dryRun ? 'DRY RUN' : 'PUBLISH',
      ),
    );
    out(
      PublishingReportFormatter.validation(
        report.result,
        blocking: blocking,
        publishableVerses: publishable,
      ),
    );
    if (blocking.isNotEmpty) {
      return _finish(
        withTarget,
        options,
        PublishExit.content,
        stage: PublishingStage.validation,
        message:
            'Publishing stopped: fix the blocking validation errors first.',
      );
    }

    // 3. Credentials (interactive only).
    if (!terminal.isInteractive) {
      return _finish(
        withTarget,
        options,
        PublishExit.access,
        stage: PublishingStage.authentication,
        message:
            'An interactive terminal is required to enter your password '
            'without it being shown.',
      );
    }
    out('\nSign in as an existing Gitartha member.\n');
    final email = terminal.readLine('Email: ');
    var password = terminal.readSecret('Password: ');
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return _finish(
        withTarget,
        options,
        PublishExit.access,
        stage: PublishingStage.authentication,
        message: 'Email and password are required.',
      );
    }

    final store = storeFactory(config);
    try {
      out('Authenticating...\n');
      final PublisherAccess access;
      try {
        access = await const PublisherAccessService().authorize(
          store,
          email: email,
          password: password,
        );
      } on PublisherAuthException catch (e) {
        return _finish(
          withTarget,
          options,
          PublishExit.access,
          stage: PublishingStage.authentication,
          message: 'Authentication failed: ${e.message}',
        );
      } on PublisherAccessDenied {
        return _finish(
          withTarget,
          options,
          PublishExit.access,
          stage: PublishingStage.authorization,
          message: PublisherAccessDenied.message,
        );
      } on RemoteStoreException catch (e) {
        return _finish(
          withTarget,
          options,
          PublishExit.access,
          stage: PublishingStage.authorization,
          message: 'Could not check your membership: ${e.message}',
        );
      } finally {
        password = null; // drop the only reference as soon as possible
      }
      withTarget.userId = access.userId;
      out('Authentication successful. Publishing permission confirmed.\n');

      // 4. Remote schema and plan (reads only).
      final PublishingPlan plan;
      try {
        await store.verifySchema();
        plan = await const PublishingPlanner().plan(
          report: report,
          scope: scope,
          store: store,
        );
      } on RemoteStoreException catch (e) {
        return _finish(
          withTarget,
          options,
          PublishExit.remote,
          stage: e.kind == RemoteErrorKind.schemaMismatch
              ? PublishingStage.remoteSchema
              : PublishingStage.planning,
          message: 'Could not read Supabase: ${e.message}',
        );
      }
      withTarget.plan = plan;
      out(PublishingReportFormatter.plan(plan));

      if (dryRun) {
        return _finish(
          withTarget,
          options,
          plan.hasErrors ? PublishExit.content : PublishExit.ok,
          message: plan.hasErrors
              ? 'The plan has errors; a confirmed publish would refuse to run.'
              : null,
        );
      }

      // 5. Confirmation and writes.
      if (!plan.canPublish) {
        return _finish(
          withTarget,
          options,
          PublishExit.content,
          stage: PublishingStage.planning,
          message:
              'Publishing refused: resolve the errors listed above first. '
              'Nothing was written.',
        );
      }
      final writes = plan.writes.length;
      if (writes == 0) {
        out(
          '\nEverything in scope is already up to date. Nothing to publish.\n',
        );
        return _finish(withTarget, options, PublishExit.ok);
      }
      final answer = terminal.readLine(
        '\nType "publish" to write $writes change(s) to ${config.host}: ',
      );
      if (answer != 'publish') {
        return _finish(
          withTarget,
          options,
          PublishExit.content,
          stage: PublishingStage.confirmation,
          message: 'Cancelled. Nothing was written.',
        );
      }

      out('Publishing...\n');
      withTarget.outcomes = await const PublishingExecutor().execute(
        plan,
        store,
      );
      final status = withTarget.status;
      return _finish(
        withTarget,
        options,
        status == PublishingStatus.success ||
                status == PublishingStatus.successWithWarnings
            ? PublishExit.ok
            : PublishExit.remote,
      );
    } finally {
      await store.close();
    }
  }

  int _finish(
    PublishingResult result,
    PublishOptions options,
    int exitCode, {
    PublishingStage? stage,
    String? message,
    bool dryRunValidation = false,
  }) {
    result
      ..completedAt = _now()
      ..stoppedAt = stage
      ..stopMessage = message;
    terminal.write(PublishingReportFormatter.result(result));
    if (options.saveReport) {
      final path = _saveReport(result);
      terminal.write('Report saved: $path\n');
    }
    return exitCode;
  }

  String _saveReport(PublishingResult result) {
    final t = result.startedAt.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final name =
        'publishing_${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}.json';
    final dir = Directory(reportDirectory)..createSync(recursive: true);
    final file = File('${dir.path}/$name');
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(result.toJson()),
    );
    return file.path;
  }
}
