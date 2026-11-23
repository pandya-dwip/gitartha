import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/content/publishing/publisher_access.dart';
import 'package:gitartha/data/content/publishing/publishing_models.dart';
import 'package:gitartha/data/content/publishing/remote_content_store.dart';

import '../../tool/publishing/publish_command.dart';
import '../../tool/publishing/publishing_config.dart';
import '../../tool/publishing/terminal.dart';
import '../unit/data/content/content_fixtures.dart';
import '../unit/data/content/publishing/fake_remote_store.dart';
import '../unit/data/content/publishing/publishing_fixtures.dart';

/// Scripted terminal: answers prompts in order and records all output.
class ScriptedTerminal implements PublisherTerminal {
  ScriptedTerminal(this.answers, {this.isInteractive = true});

  final List<String> answers;
  final List<String> prompts = [];
  final StringBuffer output = StringBuffer();
  int secretsRead = 0;

  @override
  final bool isInteractive;

  @override
  void write(String text) => output.write(text);

  @override
  String? readLine(String prompt) {
    prompts.add(prompt);
    return answers.isEmpty ? null : answers.removeAt(0);
  }

  @override
  String? readSecret(String prompt) {
    prompts.add(prompt);
    secretsRead++;
    return answers.isEmpty ? null : answers.removeAt(0);
  }

  String get text => output.toString();
}

void main() {
  late FakeRemoteStore remote;
  late int storesCreated;
  late Directory reports;

  final config = PublishingConfig.load(
    envFile: 'does-not-exist.env',
    environment: {
      'SUPABASE_URL': 'https://example-project.supabase.co',
      'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_TESTKEY',
    },
  );

  setUp(() async {
    remote = newRemote();
    storesCreated = 0;
    reports = await Directory.systemTemp.createTemp('gitartha_reports');
  });
  tearDown(() => reports.delete(recursive: true));

  PublishCommand command(
    ScriptedTerminal terminal, {
    MapContentSource? content,
    PublishingConfig Function(String)? configLoader,
  }) => PublishCommand(
    terminal: terminal,
    content: content ?? repository({1: approvedChapterOne()}),
    storeFactory: (_) {
      storesCreated++;
      return remote;
    },
    configLoader: configLoader ?? (_) => config,
    reportDirectory: reports.path,
  );

  PublishOptions opts(List<String> args) => PublishOptions.parse(args);

  group('arguments', () {
    test('scope flags, modes and credential guards', () {
      expect(opts(['--all']).mode, PublishMode.validateOnly); // safe default
      expect(opts(['--chapter=1', '--confirm']).mode, PublishMode.confirm);
      expect(opts(['--chapter=1', '--verse=41']).scope.verseNumber, 41);
      for (final bad in [
        ['--all', '--chapter=1'],
        <String>[],
        ['--chapter=19'],
        ['--chapter=0'],
        ['--verse=3'],
        ['--chapter=12', '--verse=21'], // chapter 12 has 20 verses
        ['--all', '--dry-run', '--confirm'],
        ['--all', '--password=secret'],
        ['--all', '--email=a@b.c'],
        ['--all', '--frobnicate'],
      ]) {
        expect(() => opts(bad), throwsFormatException, reason: '$bad');
      }
    });
  });

  group('validate-only', () {
    test('needs no configuration, credentials or Supabase', () async {
      final terminal = ScriptedTerminal([]);
      final exit = await command(
        terminal,
        configLoader: (_) => throw StateError('config must not be loaded'),
      ).run(opts(['--all', '--validate-only']));

      expect(exit, PublishExit.ok);
      expect(storesCreated, 0);
      expect(terminal.prompts, isEmpty);
      expect(terminal.text, contains('Publishable in scope:'));
    });

    test('blocking errors give a non-zero exit code', () async {
      final exit = await command(
        ScriptedTerminal([]),
        content: repository({
          1: approvedChapterOne([approvedVerse(1, 1), approvedVerse(1, 1)]),
        }),
      ).run(opts(['--chapter=1', '--validate-only']));
      expect(exit, PublishExit.content);
      expect(storesCreated, 0);
    });
  });

  group('authentication and permission', () {
    test(
      'an authorized editor can preview (dry run): nothing is written',
      () async {
        final terminal = ScriptedTerminal([editorEmail, editorPassword]);
        final cmd = command(terminal);
        final exit = await cmd.run(opts(['--chapter=1', '--dry-run']));

        expect(exit, PublishExit.ok, reason: terminal.text);
        expect(remote.writes, isEmpty);
        expect(remote.closed, isTrue);
        expect(terminal.secretsRead, 1);
        expect(terminal.text, contains('Authentication successful'));
        expect(terminal.text, contains('Shlokas to insert:'));
        expect(terminal.text, contains('No database changes were made.'));
        expect(terminal.text, isNot(contains(editorPassword)));
        expect(cmd.lastResult!.status, PublishingStatus.dryRun);
        expect(cmd.lastResult!.userId, editorId);
      },
    );

    test('invalid credentials stop before any content is read', () async {
      final terminal = ScriptedTerminal([editorEmail, 'wrong-password']);
      final exit = await command(
        terminal,
      ).run(opts(['--chapter=1', '--dry-run']));
      expect(exit, PublishExit.access);
      expect(remote.log, ['signIn', 'close']);
      expect(terminal.text, contains('Invalid email or password.'));
      expect(terminal.text, isNot(contains('wrong-password')));
    });

    for (final (who, email, password) in [
      ('a read-only member', readerEmail, readerPassword),
      ('a user without membership', strangerEmail, strangerPassword),
    ]) {
      test('$who is denied and nothing is written', () async {
        final terminal = ScriptedTerminal([email, password, 'publish']);
        final exit = await command(
          terminal,
        ).run(opts(['--chapter=1', '--confirm']));
        expect(exit, PublishExit.access);
        expect(terminal.text, contains(PublisherAccessDenied.message));
        expect(remote.writes, isEmpty);
        expect(
          remote.log.where(
            (l) => l.startsWith('read ') && l != 'read app_members',
          ),
          isEmpty,
        );
        expect(remote.closed, isTrue);
        // The permission itself is untouched.
        expect(remote.members, {editorId: true, readerId: false});
      });
    }

    test(
      'a non-interactive terminal is refused (password cannot be hidden)',
      () async {
        final terminal = ScriptedTerminal([
          editorEmail,
          editorPassword,
        ], isInteractive: false);
        final exit = await command(
          terminal,
        ).run(opts(['--chapter=1', '--dry-run']));
        expect(exit, PublishExit.access);
        expect(storesCreated, 0);
        expect(terminal.secretsRead, 0);
      },
    );

    test(
      'a privileged key in the configuration is refused before anything',
      () async {
        final terminal = ScriptedTerminal([editorEmail, editorPassword]);
        final exit = await command(
          terminal,
          configLoader: (_) => PublishingConfig.load(
            envFile: 'does-not-exist.env',
            environment: {
              'SUPABASE_URL': 'https://example-project.supabase.co',
              'SUPABASE_PUBLISHABLE_KEY': 'sb_secret_TESTKEY',
            },
          ),
        ).run(opts(['--chapter=1', '--dry-run']));
        expect(exit, PublishExit.usage);
        expect(storesCreated, 0);
        expect(terminal.text, contains('refuses privileged keys'));
      },
    );
  });

  group('confirmed publishing', () {
    test('publishes after typing "publish", then is idempotent', () async {
      final first = ScriptedTerminal([editorEmail, editorPassword, 'publish']);
      final cmd = command(first);
      expect(await cmd.run(opts(['--chapter=1', '--confirm'])), PublishExit.ok);
      expect(remote.count('shlokas'), 3);
      expect(
        cmd.lastResult!.status.jsonValue,
        anyOf('success', 'success_with_warnings'),
      );

      remote = newRemote()..tables.addAll(remote.tables);
      final second = ScriptedTerminal([editorEmail, editorPassword]);
      expect(
        await command(second).run(opts(['--chapter=1', '--confirm'])),
        PublishExit.ok,
      );
      expect(second.text, contains('Nothing to publish'));
      expect(remote.writes, isEmpty);
    });

    test('anything other than "publish" cancels without writing', () async {
      final terminal = ScriptedTerminal([editorEmail, editorPassword, 'yes']);
      final exit = await command(
        terminal,
      ).run(opts(['--chapter=1', '--confirm']));
      expect(exit, PublishExit.content);
      expect(remote.writes, isEmpty);
      expect(terminal.text, contains('Cancelled. Nothing was written.'));
    });

    test('a remote schema mismatch stops before planning', () async {
      remote.schemaMatches = false;
      final terminal = ScriptedTerminal([
        editorEmail,
        editorPassword,
        'publish',
      ]);
      final exit = await command(
        terminal,
      ).run(opts(['--chapter=1', '--confirm']));
      expect(exit, PublishExit.remote);
      expect(remote.writes, isEmpty);
      expect(terminal.text, contains('hindi_meaning_note'));
    });

    test('a partial failure is reported with a non-zero exit code', () async {
      remote.failWrite = (table, rows) => table == 'shloka_source_attributions'
          ? const RemoteStoreException(RemoteErrorKind.network, 'offline')
          : null;
      final terminal = ScriptedTerminal([
        editorEmail,
        editorPassword,
        'publish',
      ]);
      final cmd = command(terminal);
      final exit = await cmd.run(opts(['--chapter=1', '--confirm']));
      expect(exit, PublishExit.remote);
      expect(cmd.lastResult!.status, PublishingStatus.partiallyCompleted);
      expect(terminal.text, contains('Re-running the same command is safe'));
    });

    test('the saved report contains no credentials', () async {
      final terminal = ScriptedTerminal([
        editorEmail,
        editorPassword,
        'publish',
      ]);
      await command(
        terminal,
      ).run(opts(['--chapter=1', '--confirm', '--save-report']));

      final files = reports.listSync().whereType<File>().toList();
      expect(
        files.single.path,
        matches(RegExp(r'publishing_\d{8}_\d{6}\.json$')),
      );
      final text = files.single.readAsStringSync();
      final json = jsonDecode(text) as Map<String, dynamic>;
      expect(json['status'], anyOf('success', 'success_with_warnings'));
      expect(json['userId'], editorId);
      expect(json['target'], 'example-project.supabase.co');
      expect((json['counts'] as Map)['shlokas'], containsPair('inserted', 3));
      for (final secret in [
        editorPassword,
        'sb_publishable_TESTKEY',
        editorEmail,
      ]) {
        expect(text, isNot(contains(secret)));
      }
    });
  });
}
