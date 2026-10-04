// import 'dart:async';
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:lexifold/data/source/local/lexi_fold_database.dart';
//
// class StudySetPagingState {
//   final List<StudySet> items;
//   final bool hasNextPage;
//   final bool isLoadingInitial;
//   final String? nextCursorId;
//
//   const StudySetPagingState({
//     required this.items,
//     required this.hasNextPage,
//     required this.isLoadingInitial,
//     required this.nextCursorId,
//   });
//
//   StudySetPagingState copyWith({StudySetPagingState? state}) {
//     return StudySetPagingState(
//       items: state?.items != null ? [...state!.items] : [],
//       hasNextPage: state?.hasNextPage ?? true,
//       isLoadingInitial: state?.isLoadingInitial ?? true,
//       nextCursorId: state?.nextCursorId,
//     );
//   }
// }
//
// class StudySetPagingNotifier
//     extends AsyncNotifier<StudySetPagingState> {
//   @override
//   FutureOr<StudySetPagingState> build() {
//     // TODO: implement build
//     throw UnimplementedError();
//   }
// }
