import 'package:drift/drift.dart';
import 'package:lexifold/data/enums/paging_metadata.dart';
import 'package:lexifold/data/source/local/lexi_fold_database.dart';

import '../../../../entities/study_set_paging_metadatas.dart';

part 'study_set_metadata_dao.g.dart';

@DriftAccessor(tables: const [StudySetPagingMetadatas])
class StudySetMetadataDao extends DatabaseAccessor<LexiFoldDatabase>
    with _$StudySetMetadataDaoMixin {
  StudySetMetadataDao(LexiFoldDatabase db) : super(db);

  Future<void> addOrUpdate(StudySetPagingMetadata entity) async {
    await into(
      studySetPagingMetadatas,
    ).insertOnConflictUpdate(entity);
  }

  Future<StudySetPagingMetadata?> getStudySetPagingMetadata(
    StudySetPagingEnum key,
  ) async {
    return await (select(studySetPagingMetadatas)
          ..where((tbl) => tbl.categoryKey.equals(key.name)))
        .getSingleOrNull();
  }

  Future<void> deleteStudySetPagingMetadata(
    StudySetPagingEnum key,
  ) async {
    await (delete(
      studySetPagingMetadatas,
    )..where((tbl) => tbl.categoryKey.equals(key.name))).go();
  }

  Future<void> clearStudySetsMetadataByCateKey(
    StudySetPagingEnum key,
  ) async {
    await (delete(
      studySetPagingMetadatas,
    )..where((tbl) => tbl.categoryKey.equals(key.name))).go();
  }
}
