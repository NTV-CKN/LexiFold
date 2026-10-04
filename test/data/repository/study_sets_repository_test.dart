import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lexifold/data/dto/response/cursor_page_result.dart';
import 'package:lexifold/data/enums/paging_metadata.dart';
import 'package:lexifold/data/model/result/base_result.dart';
import 'package:lexifold/data/source/local/study_set_source/study_sets_source_local.dart';
import 'package:lexifold/data/source/remote/study_set_source_remote.dart';
import 'package:lexifold/data/source/local/lexi_fold_database.dart';
import 'package:lexifold/data/repository/study_sets_repository.dart'; // sửa path nếu khác

class MockStudySetsSourceLocal extends Mock
    implements StudySetsSourceLocal {}

class MockStudySetSourceRemote extends Mock
    implements StudySetSourceRemote {}

StudySet _fakeStudySet(String id) {
  final now = DateTime.now();
  return StudySet(
    id: id,
    title: "Study set $id",
    subDescription: null,
    isPublic: false,
    sourceLanguage: "en",
    targetLanguage: "vi",
    createdAt: now,
    updatedAt: now,
  );
}

List<StudySet> _fakeStudySets(int count, {int startAt = 1}) {
  return List.generate(count, (i) => _fakeStudySet('${startAt + i}'));
}

void main() {
  late MockStudySetsSourceLocal mockLocal;
  late MockStudySetSourceRemote mockRemote;
  late StudySetsRepositoryImpl repository;

  const key = StudySetPagingEnum.ALL_STUDY_SET;
  const limit = 20;

  setUp(() {
    mockLocal = MockStudySetsSourceLocal();
    mockRemote = MockStudySetSourceRemote();
    repository = StudySetsRepositoryImpl(
      local: mockLocal,
      remote: mockRemote,
    );

    // Fallback value cho mocktail khi verify/any() với kiểu phức tạp.
    registerFallbackValue(
      StudySetPagingMetadata(
        categoryKey: key.name,
        nextCursorId: null,
        lastUpdatedAt: DateTime.now(),
      ),
    );
    registerFallbackValue(<StudySet>[]);
  });

  group('getStudySetsPaging - cache rỗng / hết hạn -> gọi Remote', () {
    test(
      'metadata == null (lần đầu mở app) -> gọi remote, lưu metadata + items',
      () async {
        when(
          () => mockLocal.getStudySetMetadata(key),
        ).thenAnswer((_) async => null);

        // metadata == null -> isCacheExpired tự động = true, nên
        // _processPagingRemoteMediator sẽ gọi clear trước khi fetch remote.
        when(
          () => mockLocal.clearStudySetsMetadataByCateKeyAndStudySets(
            key,
          ),
        ).thenAnswer((_) async {});

        final remoteItems = _fakeStudySets(limit);
        when(
          () => mockRemote.fetchStudySets(limit: limit, cursor: null),
        ).thenAnswer(
          (_) async =>
              CursorPageResult(items: remoteItems, hasNextPage: true),
        );

        when(
          () => mockLocal.addOrUpdateStudySetMetadata(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocal.saveStudySets(any()),
        ).thenAnswer((_) async {});

        final result = await repository.getStudySetsPaging(
          limit: limit,
          key: key,
        );

        expect(result.items.length, limit);
        verify(
          () => mockLocal.clearStudySetsMetadataByCateKeyAndStudySets(
            key,
          ),
        ).called(1);
        verify(
          () => mockRemote.fetchStudySets(limit: limit, cursor: null),
        ).called(1);

        // Vì trả đủ `limit` item -> nextCursorId phải là id item cuối (không null)
        final captured =
            verify(
                  () => mockLocal.addOrUpdateStudySetMetadata(
                    captureAny(),
                  ),
                ).captured.single
                as StudySetPagingMetadata;
        expect(captured.nextCursorId, remoteItems.last.id);
      },
    );

    test(
      'cache hết hạn (lastUpdatedAt quá 3 giờ) -> reset metadata + gọi remote với cursor null',
      () async {
        final oldMetadata = StudySetPagingMetadata(
          categoryKey: key.name,
          nextCursorId: 'cursor_old',
          lastUpdatedAt: DateTime.now().subtract(
            const Duration(hours: 4),
          ),
        );

        when(
          () => mockLocal.getStudySetMetadata(key),
        ).thenAnswer((_) async => oldMetadata);
        when(
          () => mockLocal.clearStudySetsMetadataByCateKeyAndStudySets(
            key,
          ),
        ).thenAnswer((_) async {});

        final remoteItems = _fakeStudySets(
          5,
        ); // ít hơn limit -> hết data
        when(
          () => mockRemote.fetchStudySets(
            limit: limit,
            cursor: null, // phải là null vì bị reset do hết hạn
          ),
        ).thenAnswer(
          (_) async => CursorPageResult(
            items: remoteItems,
            hasNextPage: false,
          ),
        );
        when(
          () => mockLocal.addOrUpdateStudySetMetadata(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocal.saveStudySets(any()),
        ).thenAnswer((_) async {});

        final result = await repository.getStudySetsPaging(
          limit: limit,
          key: key,
        );

        expect(result.items.length, 5);
        verify(
          () => mockLocal.clearStudySetsMetadataByCateKeyAndStudySets(
            key,
          ),
        ).called(1);
        verify(
          () => mockRemote.fetchStudySets(limit: limit, cursor: null),
        ).called(1);

        // items.length (5) != limit (20) -> nextCursorId phải là null (hết data)
        final captured =
            verify(
                  () => mockLocal.addOrUpdateStudySetMetadata(
                    captureAny(),
                  ),
                ).captured.single
                as StudySetPagingMetadata;
        expect(captured.nextCursorId, isNull);
      },
    );
  });

  group('getStudySetsPaging - cache còn hạn -> ưu tiên đọc Local', () {
    test(
      'lần đầu cuộn (nextCursorId null từ UI) -> đọc local trước, không gọi remote nếu local có data',
      () async {
        final validMetadata = StudySetPagingMetadata(
          categoryKey: key.name,
          nextCursorId: 'cursor_20',
          lastUpdatedAt: DateTime.now(), // còn hạn
        );

        when(
          () => mockLocal.getStudySetMetadata(key),
        ).thenAnswer((_) async => validMetadata);

        final localItems = _fakeStudySets(limit);
        when(
          () => mockLocal.getStudySetsPaging(
            limit: limit,
            nextCursorId: null,
          ),
        ).thenAnswer((_) async => localItems);

        final result = await repository.getStudySetsPaging(
          limit: limit,
          key: key,
          nextCursorId: null,
        );

        expect(result.items.length, limit);
        verifyNever(
          () => mockRemote.fetchStudySets(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
          ),
        );
      },
    );

    test(
      'UI cuộn đúng tới mép đã biết (nextCursorId UI == metadata.nextCursorId) '
      '-> không đọc local, đi thẳng remote',
      () async {
        final validMetadata = StudySetPagingMetadata(
          categoryKey: key.name,
          nextCursorId: 'cursor_20',
          lastUpdatedAt: DateTime.now(),
        );

        when(
          () => mockLocal.getStudySetMetadata(key),
        ).thenAnswer((_) async => validMetadata);

        final remoteItems = _fakeStudySets(limit, startAt: 21);
        when(
          () => mockRemote.fetchStudySets(
            limit: limit,
            cursor: 'cursor_20',
          ),
        ).thenAnswer(
          (_) async =>
              CursorPageResult(items: remoteItems, hasNextPage: true),
        );
        when(
          () => mockLocal.addOrUpdateStudySetMetadata(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocal.saveStudySets(any()),
        ).thenAnswer((_) async {});

        final result = await repository.getStudySetsPaging(
          limit: limit,
          key: key,
          nextCursorId: 'cursor_20', // == metadata.nextCursorId
        );

        expect(result.items.length, limit);
        // Không được gọi local.getStudySetsPaging vì điều kiện bị skip
        verifyNever(
          () => mockLocal.getStudySetsPaging(
            limit: any(named: 'limit'),
            nextCursorId: any(named: 'nextCursorId'),
          ),
        );
        verify(
          () => mockRemote.fetchStudySets(
            limit: limit,
            cursor: 'cursor_20',
          ),
        ).called(1);
      },
    );

    // LƯU Ý: Đây không phải "fallback về remote" như có thể kỳ vọng ban đầu.
    // _processPagingRemoteMediator chỉ gọi remote khi:
    //   metadata == null || metadata.nextCursorId != null
    // Nếu metadata đã nói "fully synced" (nextCursorId == null), code hiện
    // tại tin tưởng tuyệt đối vào đó và KHÔNG gọi lại remote, kể cả khi local
    // thực tế đang rỗng (ví dụ do bị xoá cục bộ mà quên xoá metadata). Đây là
    // 1 edge case đáng cân nhắc sửa ở tầng repository nếu muốn an toàn hơn.
    // Test này chỉ đang mô tả đúng hành vi hiện tại của code.
    test(
      'metadata fully synced (nextCursorId == null) nhưng local rỗng '
      '-> KHÔNG gọi remote, trả về mảng rỗng (hành vi thật của code hiện tại)',
      () async {
        final validMetadata = StudySetPagingMetadata(
          categoryKey: key.name,
          nextCursorId: null, // fully synced
          lastUpdatedAt: DateTime.now(),
        );

        when(
          () => mockLocal.getStudySetMetadata(key),
        ).thenAnswer((_) async => validMetadata);
        when(
          () => mockLocal.getStudySetsPaging(
            limit: limit,
            nextCursorId: null,
          ),
        ).thenAnswer((_) async => <StudySet>[]); // local rỗng

        final result = await repository.getStudySetsPaging(
          limit: limit,
          key: key,
        );

        expect(result.items, isEmpty);
        verifyNever(
          () => mockRemote.fetchStudySets(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
          ),
        );
      },
    );

    test(
      'metadata CHƯA fully synced (nextCursorId khác null) và local rỗng '
      '-> fallback gọi remote với cursor từ metadata',
      () async {
        final notFullySyncedMetadata = StudySetPagingMetadata(
          categoryKey: key.name,
          nextCursorId: 'cursor_resume', // còn data chưa kéo hết
          lastUpdatedAt: DateTime.now(),
        );

        when(
          () => mockLocal.getStudySetMetadata(key),
        ).thenAnswer((_) async => notFullySyncedMetadata);
        // nextCursorId UI (null) != metadata.nextCursorId -> vẫn đọc local trước
        when(
          () => mockLocal.getStudySetsPaging(
            limit: limit,
            nextCursorId: null,
          ),
        ).thenAnswer((_) async => <StudySet>[]); // local rỗng

        final remoteItems = _fakeStudySets(limit);
        when(
          () => mockRemote.fetchStudySets(
            limit: limit,
            cursor: 'cursor_resume',
          ),
        ).thenAnswer(
          (_) async =>
              CursorPageResult(items: remoteItems, hasNextPage: true),
        );
        when(
          () => mockLocal.addOrUpdateStudySetMetadata(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocal.saveStudySets(any()),
        ).thenAnswer((_) async {});

        final result = await repository.getStudySetsPaging(
          limit: limit,
          key: key,
        );

        expect(result.items.length, limit);
        verify(
          () => mockRemote.fetchStudySets(
            limit: limit,
            cursor: 'cursor_resume',
          ),
        ).called(1);
      },
    );
  });

  group('_processPagingLocal - hasNextPage theo isFullySynced', () {
    // Test gián tiếp qua getStudySetsPaging vì hàm private không gọi thẳng được.

    test(
      'isFullySynced = true, local trả ít hơn limit -> hasNextPage = false (đúng là hết data)',
      () async {
        final fullySyncedMetadata = StudySetPagingMetadata(
          categoryKey: key.name,
          nextCursorId: null, // fully synced
          lastUpdatedAt: DateTime.now(),
        );

        when(
          () => mockLocal.getStudySetMetadata(key),
        ).thenAnswer((_) async => fullySyncedMetadata);

        final partialItems = _fakeStudySets(5); // ít hơn limit
        when(
          () => mockLocal.getStudySetsPaging(
            limit: limit,
            nextCursorId: null,
          ),
        ).thenAnswer((_) async => partialItems);

        final result = await repository.getStudySetsPaging(
          limit: limit,
          key: key,
        );

        expect(result.items.length, 5);
        expect(
          result.hasNextPage,
          isFalse,
          reason:
              'Đã fully synced, local trả ít hơn limit => đúng là hết dữ liệu thật',
        );
      },
    );

    test('isFullySynced = false, local trả ít hơn limit (do bị xoá cục bộ...) '
        '-> hasNextPage = true (tránh ngắt cuộn sớm)', () async {
      final notFullySyncedMetadata = StudySetPagingMetadata(
        categoryKey: key.name,
        nextCursorId: 'cursor_some', // server còn data chưa kéo hết
        lastUpdatedAt: DateTime.now(),
      );

      when(
        () => mockLocal.getStudySetMetadata(key),
      ).thenAnswer((_) async => notFullySyncedMetadata);

      // nextCursorId UI khác metadata.nextCursorId -> vẫn đọc local trước
      final partialItems = _fakeStudySets(5);
      when(
        () => mockLocal.getStudySetsPaging(
          limit: limit,
          nextCursorId: null,
        ),
      ).thenAnswer((_) async => partialItems);

      final result = await repository.getStudySetsPaging(
        limit: limit,
        key: key,
        nextCursorId: null,
      );

      expect(result.items.length, 5);
      expect(
        result.hasNextPage,
        isTrue,
        reason:
            'Chưa fully synced, local thiếu item (do bị xoá cục bộ...) '
            '=> vẫn phải cho UI cuộn tiếp để hỏi remote, không ngắt sớm',
      );
    });
  });

  group('forceRefresh', () {
    test(
      'forceRefresh = true -> luôn clear metadata + gọi remote với cursor null, '
      'bỏ qua local dù cache còn hạn',
      () async {
        final validMetadata = StudySetPagingMetadata(
          categoryKey: key.name,
          nextCursorId: 'cursor_20',
          lastUpdatedAt: DateTime.now(), // còn hạn
        );

        when(
          () => mockLocal.getStudySetMetadata(key),
        ).thenAnswer((_) async => validMetadata);
        when(
          () => mockLocal.clearStudySetsMetadataByCateKeyAndStudySets(
            key,
          ),
        ).thenAnswer((_) async {});

        final remoteItems = _fakeStudySets(limit);
        when(
          () => mockRemote.fetchStudySets(limit: limit, cursor: null),
        ).thenAnswer(
          (_) async =>
              CursorPageResult(items: remoteItems, hasNextPage: true),
        );
        when(
          () => mockLocal.addOrUpdateStudySetMetadata(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocal.saveStudySets(any()),
        ).thenAnswer((_) async {});

        final result = await repository.getStudySetsPaging(
          limit: limit,
          key: key,
          forceRefresh: true,
        );

        expect(result.items.length, limit);
        verify(
          () => mockLocal.clearStudySetsMetadataByCateKeyAndStudySets(
            key,
          ),
        ).called(1);
        verifyNever(
          () => mockLocal.getStudySetsPaging(
            limit: any(named: 'limit'),
            nextCursorId: any(named: 'nextCursorId'),
          ),
        );
        verify(
          () => mockRemote.fetchStudySets(limit: limit, cursor: null),
        ).called(1);
      },
    );
  });

  group('addOrUpdateStudySets / addOrUpdateStudySetsToServer', () {
    test(
      'addOrUpdateStudySets: thành công -> trả về true, gọi đúng local',
      () async {
        final vocabs = <Vocabulary>[];
        final studySet = _fakeStudySet('1');

        when(
          () =>
              mockLocal.addOrUpdateStudySet(vocabs, studySet, false),
        ).thenAnswer((_) async => true);

        final result = await repository.addOrUpdateStudySets(
          vocabs,
          studySet,
          false,
        );

        expect(result, isTrue);
        verify(
          () =>
              mockLocal.addOrUpdateStudySet(vocabs, studySet, false),
        ).called(1);
      },
    );

    test(
      'addOrUpdateStudySets: local throw exception -> trả về false, không rethrow',
      () async {
        final vocabs = <Vocabulary>[];
        final studySet = _fakeStudySet('1');

        when(
          () =>
              mockLocal.addOrUpdateStudySet(vocabs, studySet, false),
        ).thenThrow(Exception('DB error'));

        final result = await repository.addOrUpdateStudySets(
          vocabs,
          studySet,
          false,
        );

        expect(result, isFalse);
      },
    );

    test(
      'addOrUpdateStudySetsToServer: gọi đúng remote và trả kết quả nguyên vẹn',
      () async {
        const payload = '{"title":"test"}';
        final expected = BaseResult(success: true, message: 'OK');

        when(
          () => mockRemote.addOrUpdateWithVocabs(false, payload),
        ).thenAnswer((_) async => expected);

        final result = await repository.addOrUpdateStudySetsToServer(
          false,
          payload,
        );

        expect(result.success, isTrue);
        expect(result.message, 'OK');
      },
    );
  });
}
