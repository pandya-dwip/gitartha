import 'package:flutter/services.dart';

import '../content_constants.dart';
import 'content_asset_loader.dart';

/// Reads the content repository from the Flutter asset bundle. The assets
/// are declared in `pubspec.yaml` under `assets/data/bhagavad_gita/`.
class AssetBundleContentSource implements ContentSource {
  AssetBundleContentSource([AssetBundle? bundle])
    : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;

  static const String _chaptersPrefix =
      '${GitaContent.rootPath}/${GitaContent.chaptersDir}/';

  @override
  String get description => 'asset bundle (${GitaContent.rootPath})';

  @override
  Future<List<String>> listChapterFiles() async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return [
      for (final key in manifest.listAssets())
        if (key.startsWith(_chaptersPrefix) &&
            !key.substring(_chaptersPrefix.length).contains('/'))
          key.substring(_chaptersPrefix.length),
    ]..sort();
  }

  @override
  Future<String> readChapterFile(String fileName) =>
      _load('$_chaptersPrefix$fileName', fileName);

  @override
  Future<String> readSourcesFile() => _load(
    '${GitaContent.rootPath}/${GitaContent.sourcesPath}',
    GitaContent.sourcesFileName,
  );

  @override
  Future<String> readSchemaFile(String fileName) =>
      _load('${GitaContent.rootPath}/schema/$fileName', fileName);

  Future<String> _load(String key, String fileName) async {
    try {
      // cache: false, so a re-import always sees the bundled bytes afresh.
      return await bundle.loadString(key, cache: false);
    } on Object catch (e) {
      throw ContentLoadException(
        fileName,
        'asset "$key" could not be loaded (is it declared in pubspec.yaml?)',
        cause: e,
      );
    }
  }
}
