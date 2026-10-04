import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/data/enums/sync_option.dart';
import 'package:lexifold/data/model/set/study_set_data.dart';
import 'package:lexifold/data/model/set/vocab_item.dart';
import 'package:lexifold/data/model/set/vocabulary_data.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

//Start-FormState: Đây là phần quản lí danh sách các card
//khi người dùng nhập liệu và xóa sửa
class StudySetFormState {
  final StudySetData studySetData;
  final List<VocabItem> cards;

  StudySetFormState({
    required this.studySetData,
    required this.cards,
  });

  StudySetFormState copyWith({
    StudySetData? studySetData,
    List<VocabItem>? cards,
  }) {
    return StudySetFormState(
      studySetData: studySetData ?? this.studySetData,
      cards: cards ?? this.cards,
    );
  }
}

class StudySetFormStateNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<
          StudySetFormState,
          (String idSet, bool isUpdate)
        > {
  VocabItem? addCard() {
    final formState = state.valueOrNull;
    if (formState != null) {
      final vocabItem = _createVocabItem(formState.studySetData.id);
      final updatedCards = [...formState.cards, vocabItem];
      state = AsyncData(
        formState.copyWith(
          cards: updatedCards,
          studySetData: formState.studySetData.copyWith(),
        ),
      );

      return vocabItem;
    }

    return null;
  }

  @override
  FutureOr<StudySetFormState> build((String, bool) args) {
    ref.onDispose(() {
      final studyFormState = state.valueOrNull;
      if (studyFormState != null) {
        for (final card in studyFormState.cards) {
          card.dispose();
        }
      }
    });
    // if (arg == null) {
    final studySetId = args.$1;

    final cards = [
      _createVocabItem(studySetId),
      _createVocabItem(studySetId),
    ];
    final studySetData = StudySetData(
      id: studySetId,
      title: "NoName",
      syncStatus: SyncOption.initialize.typeName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return StudySetFormState(
      studySetData: studySetData,
      cards: cards,
    );
    // }
  }

  /// Kiểm tra tính hợp lệ của Form nhập liệu.
  ///
  /// Trả về `true` nếu toàn bộ thông tin hợp lệ.
  /// Trả về `false` nếu tiêu đề trống, thiếu thẻ hoặc thẻ chưa điền đủ nội dung.
  bool validateForm() {
    final formState = state.valueOrNull;
    if (formState == null) return false;

    if (formState.studySetData.title.trim().isEmpty) return false;

    if (formState.cards.length < 2) return false;

    for (final card in formState.cards) {
      final term = card.vocabulary.term.trim();
      final definition = card.vocabulary.definition.trim();

      if (term.isEmpty || definition.isEmpty) {
        return false;
      }
    }

    return true;
  }

  void updateDefinition(String id, String val) {
    final value = state.valueOrNull;
    if (val.isEmpty || value == null) return;

    final firstItemMatched = value.cards.firstWhere(
      (item) => item.vocabulary.id == id,
    );
    firstItemMatched.vocabulary.definition = val;
  }

  void updateTerm(String id, String val) {
    final value = state.valueOrNull;
    if (val.isEmpty || value == null) return;

    final firstItemMatched = value.cards.firstWhere(
      (item) => item.vocabulary.id == id,
    );
    firstItemMatched.vocabulary.term = val;
  }
}

final studySetFormStateProvider = AsyncNotifierProvider.autoDispose
    .family<
      StudySetFormStateNotifier,
      StudySetFormState,
      (String, bool)
    >(StudySetFormStateNotifier.new);
//End-FormState

//Các hàm phụ trợ
VocabItem _createVocabItem(String idSet) {
  return VocabItem(
    VocabularyData(
      id: uuid.v4(),
      studySetId: idSet,
      term: "",
      definition: "",
      updatedAt: DateTime.now(),
    ),
    defineFocus: FocusNode(),
    termFocus: FocusNode(),
  );
}
