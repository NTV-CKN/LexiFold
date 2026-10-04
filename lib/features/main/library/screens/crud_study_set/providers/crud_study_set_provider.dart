import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../data/model/result/base_result.dart';
import '../../../../../../data/source/local/lexi_fold_database.dart';
import '../../../../../../providers/study_sets/study_sets_core_provider.dart';
import 'form_state_provider.dart';

//Start-CRUD StudySets
class CRUDStudySetsNotifier
    extends AutoDisposeAsyncNotifier<BaseResult?> {
  @override
  FutureOr<BaseResult?> build() {
    return null;
  }

  Future<void> addOrUpdateStudySets((String, bool) args) async {
    state = AsyncLoading();

    final formStateNotifier = ref.read(
      studySetFormStateProvider(args).notifier,
    );
    if (!formStateNotifier.validateForm()) {
      state = AsyncData(
        BaseResult(success: false, message: "Form invalid!"),
      );
      return;
    }

    final formState = formStateNotifier.state.valueOrNull;
    if (formState == null) {
      state = AsyncData(
        BaseResult(success: false, message: "Form state is null!"),
      );
      return;
    }

    state = await AsyncValue.guard(() async {
      final now = DateTime.now();

      //Trích xuất ra thực thể StudySet
      final studySet = StudySet(
        id: formState.studySetData.id,
        title: formState.studySetData.title.trim(),
        subDescription: formState.studySetData.subDescription?.trim(),
        isPublic: formState.studySetData.isPublic,
        createdAt: now,
        updatedAt: now,
        sourceLanguage: formState.studySetData.sourceLanguage,
        targetLanguage: formState.studySetData.targetLanguage,
      );

      //Trích xuất danh sách từ vựng
      final vocabs = formState.cards
          .map<Vocabulary>(
            (item) => Vocabulary(
              id: item.vocabulary.id,
              studySetId: item.vocabulary.studySetId,
              term: item.vocabulary.term,
              definition: item.vocabulary.definition,
              termLanguage: item.vocabulary.termLanguage,
              definitionLanguage: item.vocabulary.definitionLanguage,
              updatedAt: item.vocabulary.updatedAt,
            ),
          )
          .toList();

      //Gọi hàm xử lí thêm hoặc cập nhật học phần
      final studySetsRepository = ref.read(
        studySetsRepositoryProvider,
      );
      final isSuccess = await studySetsRepository
          .addOrUpdateStudySets(vocabs, studySet, args.$2);

      return BaseResult(
        success: isSuccess,
        message: isSuccess ? "Save success" : "Save failed",
      );
    });
  }
}

final crudStudySetProvider = AsyncNotifierProvider.autoDispose(
  CRUDStudySetsNotifier.new,
);
//End-CRUD StudySets
