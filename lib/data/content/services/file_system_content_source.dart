import 'dart:convert';
import 'dart:io';

import '../content_constants.dart';
import 'content_asset_loader.dart';

/// Reads the content repository from disk (`dart run` CLI and tests).
/// Read-only: nothing here writes, renames or deletes files.
class FileSystemContentSource implements ContentSource {
  FileSystemContentSource([String rootPath = GitaContent.rootPath])
    : root = Directory(rootPath);

  final Directory root;

  @override
  String get description => root.path;

  @override
  Future<List<String>> listChapterFiles() async {
    final dir = Directory('${root.path}/${GitaContent.chaptersDir}');
    if (!dir.existsSync()) {
      throw ContentLoadException(dir.path, 'chapters directory not found');
    }
    return [
      for (final entity in dir.listSync())
        if (entity is File) entity.uri.pathSegments.last,
    ]..sort();
  }

  @override
  Future<String> readChapterFile(String fileName) =>
      _read('${GitaContent.chaptersDir}/$fileName', fileName);

  @override
  Future<String> readSourcesFile() =>
      _read(GitaContent.sourcesPath, GitaContent.sourcesFileName);

  @override
  Future<String> readSchemaFile(String fileName) =>
      _read('schema/$fileName', fileName);

  Future<String> _read(String relativePath, String fileName) async {
    final file = File('${root.path}/$relativePath');
    if (!file.existsSync()) {
      throw ContentLoadException(fileName, 'file not found: ${file.path}');
    }
    try {
      return await file.readAsString(encoding: utf8);
    } on Object catch (e) {
      throw ContentLoadException(
        fileName,
        'could not read ${file.path}',
        cause: e,
      );
    }
  }
}
