import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/local_database_providers.dart';
import 'repositories/content_repository.dart';
import 'services/asset_bundle_content_source.dart';
import 'services/content_asset_loader.dart';

/// The bundled content repository (`assets/data/bhagavad_gita/`).
final contentSourceProvider = Provider<ContentSource>(
  (ref) => AssetBundleContentSource(),
);

/// Validation and import of the bundled content into the local database.
/// Reading this provider does nothing by itself. Imports happen only when a
/// caller explicitly invokes `importDraft()` or `importApproved()`.
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(
    source: ref.watch(contentSourceProvider),
    database: ref.watch(appDatabaseProvider),
  ),
);
