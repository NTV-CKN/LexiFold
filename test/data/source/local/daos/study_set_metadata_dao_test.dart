import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexifold/data/enums/paging_metadata.dart';
import 'package:lexifold/data/source/local/daos/study_sets/study_set_metadata_dao.dart';
import 'package:lexifold/data/source/local/lexi_fold_database.dart';

void main() {
  late LexiFoldDatabase db;
  late StudySetMetadataDao dao;

  //Chuẩn bị
  setUp(() {
    db = LexiFoldDatabase.withDb(NativeDatabase.memory());
    dao = db.studySetMetadataDao;
  });

  //Giải phòng
  tearDown(() async {
    await db.close();
  });

  group("Test Suite", () {
    test("Kiểm tra lấy ra dữ liệu trống", () async {
      final result = await dao.getStudySetPagingMetadata(
        StudySetPagingEnum.ALL_STUDY_SET,
      );

      expect(result, isNull);
    });

    test("Thêm thành công ALL_STUDY_SET và kiểm tra", () async {
      await dao.addOrUpdate(
        StudySetPagingMetadata(
          lastUpdatedAt: DateTime.now(),
          categoryKey: StudySetPagingEnum.ALL_STUDY_SET.name,
          nextCursorId: "next_123",
        ),
      );

      //Gọi hàm lấy ra record vừa tạo
      final result = await dao.getStudySetPagingMetadata(
        StudySetPagingEnum.ALL_STUDY_SET,
      );

      expect(result, isNotNull);
      expect(
        result!.categoryKey,
        equals(StudySetPagingEnum.ALL_STUDY_SET.name),
      );
      expect(result.nextCursorId, equals("next_123"));
    });

    test("Kiểm tra ghi đè dữ liệu trùng key", () async {
      final initialData = StudySetPagingMetadata(
        categoryKey: StudySetPagingEnum.ALL_STUDY_SET.name,
        nextCursorId: 'cursor_v1',
        lastUpdatedAt: DateTime.now(),
      );
      await dao.addOrUpdate(initialData);

      //Update
      final lastUpdateV2 = DateTime.now();
      final updatedData = StudySetPagingMetadata(
        categoryKey: StudySetPagingEnum.ALL_STUDY_SET.name,
        nextCursorId: 'cursor_v2',
        lastUpdatedAt: lastUpdateV2,
      );
      await dao.addOrUpdate(updatedData);

      final result = await dao.getStudySetPagingMetadata(
        StudySetPagingEnum.ALL_STUDY_SET,
      );
      expect(result!.nextCursorId, equals('cursor_v2'));
      expect(
        result.lastUpdatedAt.second,
        equals(lastUpdateV2.second),
      );
      expect(
        result.lastUpdatedAt.minute,
        equals(lastUpdateV2.minute),
      );
      expect(result.lastUpdatedAt.hour, equals(lastUpdateV2.hour));
    });

    test(
      'deleteStudySetPagingMetadata xóa đúng record theo Key',
      () async {
        final metadata = StudySetPagingMetadata(
          categoryKey: StudySetPagingEnum.ALL_STUDY_SET.name,
          nextCursorId: 'cursor_123',
          lastUpdatedAt: DateTime.now(),
        );
        await dao.addOrUpdate(metadata);

        //Thực thi xóa
        await dao.deleteStudySetPagingMetadata(
          StudySetPagingEnum.ALL_STUDY_SET,
        );

        final result = await dao.getStudySetPagingMetadata(
          StudySetPagingEnum.ALL_STUDY_SET,
        );
        expect(result, isNull);
      },
    );
  });
}
