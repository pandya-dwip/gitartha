// Publishes approved Bhagavad Gita content from assets/data/bhagavad_gita
// to the Supabase database, as an authorized member, under RLS.
//
//   dart run tool/publish_gita_content.dart --all --validate-only
//   dart run tool/publish_gita_content.dart --chapter=1 --dry-run
//   dart run tool/publish_gita_content.dart --chapter=1 --confirm
//   dart run tool/publish_gita_content.dart --chapter=1 --verse=41 --dry-run
//   dart run tool/publish_gita_content.dart --help
//
// Safety:
//   * Uses only the publishable key, plus YOUR session (email + hidden
//     password prompt). Secret / service-role keys are refused.
//   * Requires your app_members.is_accessible = true; RLS has the final say.
//   * Publishes only complete, approved, sourced content (strict rules).
//   * Writes only with --confirm, after a preview and typing "publish".
//   * Never deletes, never restores soft-deleted rows, never touches
//     memberships or personal data.
//
// See docs/content/CONTENT_PUBLISHING.md.

import 'dart:io';

import 'package:gitartha/data/content/services/file_system_content_source.dart';

import 'publishing/publish_command.dart';
import 'publishing/supabase_remote_content_store.dart';
import 'publishing/terminal.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(PublishOptions.usage);
    return;
  }
  final PublishOptions options;
  try {
    options = PublishOptions.parse(args);
  } on FormatException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln()
      ..writeln(PublishOptions.usage);
    exitCode = PublishExit.usage;
    return;
  }

  exitCode = await PublishCommand(
    terminal: const StdioTerminal(),
    content: FileSystemContentSource(),
    storeFactory: SupabaseRemoteContentStore.new,
  ).run(options);
}
