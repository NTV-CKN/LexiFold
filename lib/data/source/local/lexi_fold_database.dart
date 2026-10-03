import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../entities/study_set_paging_metadatas.dart';
import '../../entities/study_sets.dart';
import '../../entities/sync_queues.dart';
import '../../entities/vocabularies.dart';
import '../../enums/paging_metadata.dart';
import '../../enums/sync_option.dart';
import 'daos/study_sets/study_set_metadata_dao.dart';
import 'daos/study_sets/study_sets_dao.dart';
import 'daos/sync_queues/sync_queues_dao.dart';

part 'lexi_fold_database.g.dart';

//flutter pub run build_runner build --delete-conflicting-outputs

@DriftDatabase(
  tables: [
    StudySets,
    Vocabularies,
    SyncQueues,
    StudySetPagingMetadatas,
  ],
  daos: [StudySetsDao, SyncQueuesDao, StudySetMetadataDao],
)
class LexiFoldDatabase extends _$LexiFoldDatabase {
  LexiFoldDatabase({QueryExecutor? executor})
    : super(executor ?? _openConnection());

  LexiFoldDatabase.withDb(NativeDatabase db) : super(db);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        for (final table in allTables) {
          await m.drop(table);
        }
        await m.createAll();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future<void> clearAllTables() async {
    await transaction(() async {
      await customStatement('PRAGMA foreign_keys = OFF;');

      try {
        for (final table in allTables) {
          await delete(table).go();
        }
      } finally {
        await customStatement('PRAGMA foreign_keys = ON;');
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, "lexifold.sqlite"));
    return NativeDatabase(file);
  });
}
