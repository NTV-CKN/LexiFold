import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/data/repository/study_sets_repository.dart';
import 'package:lexifold/data/source/local/study_set_source/study_sets_source_local.dart';
import 'package:lexifold/data/source/remote/study_set_source_remote.dart';
import 'package:lexifold/providers/core/api_client_provider.dart';
import 'package:lexifold/providers/core/local_db/lexi_fold_db_provider.dart';

//source local
final studySetsLocalSourceProvider = Provider((ref) {
  final studySetsDao = ref.read(studySetsDaoProvider);
  final studySetMetadataDao = ref.read(studySetMetadataDaoProvider);

  return StudySetsSourceLocalImpl(
    studySetsDao: studySetsDao,
    studySetMetadataDao: studySetMetadataDao,
  );
});

//source remote
final studySetsRemoteSourceProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);

  return StudySetSourceRemoteImpl(apiClient);
});

//repository
final studySetsRepositoryProvider = Provider((ref) {
  final studySetsLocal = ref.read(studySetsLocalSourceProvider);
  final studySetsRemote = ref.read(studySetsRemoteSourceProvider);

  return StudySetsRepositoryImpl(
    local: studySetsLocal,
    remote: studySetsRemote,
  );
});
