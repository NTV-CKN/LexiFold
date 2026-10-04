import 'package:lexifold/data/enums/paging_metadata.dart';
import 'package:lexifold/data/source/local/daos/study_sets/study_set_metadata_dao.dart';
import 'package:lexifold/data/source/local/daos/study_sets/study_sets_dao.dart';
import 'package:lexifold/data/source/local/lexi_fold_database.dart';

///Lớp này đảm nhận vai trò thao tác học phần và từ vựng của học phần
///ở phía local database - thông qua Drift
abstract class StudySetsSourceLocal {
  const StudySetsSourceLocal();

  Future<bool> addOrUpdateStudySet(
    List<Vocabulary> vocabulariesLst,
    StudySet studySet,
    bool isUpdate,
  );

  Future<StudySetPagingMetadata?> getStudySetMetadata(
    StudySetPagingEnum key,
  );

  Future<void> deleteStudySetMetadata(StudySetPagingEnum key);

  Future<void> addOrUpdateStudySetMetadata(
    StudySetPagingMetadata entity,
  );

  Future<List<StudySet>> getStudySetsPaging({
    required int limit,
    String? nextCursorId,
  });

  Future<void> clearStudySetsMetadataByCateKeyAndStudySets(
    StudySetPagingEnum key,
  );

  Future<void> saveStudySets(List<StudySet> studySets);
}

class StudySetsSourceLocalImpl extends StudySetsSourceLocal {
  final StudySetsDao _studySetsDao;
  final StudySetMetadataDao _studySetMetadataDao;

  const StudySetsSourceLocalImpl({
    required this._studySetsDao,
    required this._studySetMetadataDao,
  });

  @override
  Future<bool> addOrUpdateStudySet(
    List<Vocabulary> vocabulariesLst,
    StudySet studySet,
    bool isUpdate,
  ) async {
    try {
      return await _studySetsDao.addOrUpdateStudySets(
        vocabulariesLst,
        studySet,
        isUpdate,
      );
    } catch (error) {
      return false;
    }
  }

  @override
  Future<StudySetPagingMetadata?> getStudySetMetadata(
    StudySetPagingEnum key,
  ) async {
    return await _studySetMetadataDao.getStudySetPagingMetadata(key);
  }

  @override
  Future<void> addOrUpdateStudySetMetadata(
    StudySetPagingMetadata entity,
  ) async {
    return await _studySetMetadataDao.addOrUpdate(entity);
  }

  @override
  Future<void> deleteStudySetMetadata(StudySetPagingEnum key) async {
    return await _studySetMetadataDao.deleteStudySetPagingMetadata(
      key,
    );
  }

  @override
  Future<List<StudySet>> getStudySetsPaging({
    required int limit,
    String? nextCursorId,
  }) async {
    return await _studySetsDao.getStudySetsPaging(
      limit: limit,
      nextCursorId: nextCursorId,
    );
  }

  @override
  Future<void> clearStudySetsMetadataByCateKeyAndStudySets(
    StudySetPagingEnum key,
  ) async {
    await _studySetMetadataDao.clearStudySetsMetadataByCateKey(key);
    await _studySetsDao.clear();
  }

  @override
  Future<void> saveStudySets(List<StudySet> studySets) async {
    await _studySetsDao.saveStudySets(studySets);
  }
}
