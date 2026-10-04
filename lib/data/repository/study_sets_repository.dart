import 'package:lexifold/data/dto/response/cursor_page_result.dart';
import 'package:lexifold/data/enums/paging_metadata.dart';
import 'package:lexifold/data/model/result/base_result.dart';
import 'package:lexifold/data/source/local/study_set_source/study_sets_source_local.dart';
import 'package:lexifold/data/source/remote/study_set_source_remote.dart';

import '../source/local/lexi_fold_database.dart';

abstract class StudySetsRepository {
  /// Hàm này sẽ gọi xuống dưới Database cục bổ để lưu hoặc cập nhật các học phần
  Future<bool> addOrUpdateStudySets(
    List<Vocabulary> vocabulariesLst,
    StudySet studySet,
    bool isUpdate,
  );

  ///Hàm này sẽ gọi lên Server để thực hiện việc gọi API thêm hoặc cập
  ///nhật dữ liệu học phần và từ vựng với payload cho trước.
  Future<BaseResult> addOrUpdateStudySetsToServer(
    bool isUpdate,
    String payload,
  );

  ///Thực hiện logic phân trang từ Drift và lấy
  ///dữ liệu ở Server cập nhật cho cục bộ.
  Future<CursorPageResult<StudySet>> getStudySetsPaging({
    required int limit,
    required StudySetPagingEnum key,
    String? nextCursorId,
    Map<String, dynamic>? filters,
    bool forceRefresh = false,
  });
}

class StudySetsRepositoryImpl implements StudySetsRepository {
  final StudySetsSourceLocal _local;
  final StudySetSourceRemote _remote;

  static const _durationRefresh = Duration(hours: 3);

  const StudySetsRepositoryImpl({
    required this._local,
    required this._remote,
  });

  @override
  Future<bool> addOrUpdateStudySets(
    List<Vocabulary> vocabulariesLst,
    StudySet studySet,
    bool isUpdate,
  ) async {
    try {
      return await _local.addOrUpdateStudySet(
        vocabulariesLst,
        studySet,
        isUpdate,
      );
    } catch (err) {
      return false;
    }
  }

  @override
  Future<BaseResult> addOrUpdateStudySetsToServer(
    bool isUpdate,
    String payload,
  ) async {
    return await _remote.addOrUpdateWithVocabs(isUpdate, payload);
  }

  ///
  /// int limit - Quy định giới hạn phần tử trả về.
  /// StudySetPagingEnum key - Dùng để lấy ra metadata paging
  /// String? nextCursorId - Được UI cuộn quản lí để yêu cầu lấy ra dữ liệu tiếp theo
  ///
  @override
  Future<CursorPageResult<StudySet>> getStudySetsPaging({
    required int limit,
    required StudySetPagingEnum key,
    String? nextCursorId,
    Map<String, dynamic>? filters,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final metadata = await _local.getStudySetMetadata(key);

    bool isCacheExpired =
        metadata == null ||
        now.difference(metadata.lastUpdatedAt) >= _durationRefresh;
    final bool isFullySynced =
        metadata?.nextCursorId == null && metadata != null;

    //Thực hiện load local trong trường hợp:
    //chưa hết hạn và forceRefresh = false
    if (!isCacheExpired && !forceRefresh) {
      //Logic này đảm bảo hệ thống chỉ gọi lấy data từ
      //local khi metadata.nextCursorId == null HOẶC
      //nextCursorId truyền từ UI == null (gọi lần đầu) HOẶC
      //giá trị của nextCursorId khác metadata.nextCursorId (đảm
      //bảo nếu metadata.nextCursorId != null thì nó cũng không tự
      //ý gọi lên server khi quay lại màn hình phân trang)
      if (isFullySynced ||
          nextCursorId == null ||
          (nextCursorId != metadata.nextCursorId)) {
        final localResult = await _processPagingLocal(
          limit: limit,
          isFullSync: isFullySynced,
          now: now,
          nextCursorId: nextCursorId,
          key: key,
        );

        //Nếu Local có dữ liệu -> Trả về
        if (localResult.items.isNotEmpty) {
          return localResult;
        }
      }
    }

    return await _processPagingRemoteMediator(
      forceRefresh: forceRefresh,
      isCacheExpired: isCacheExpired,
      now: now,
      key: key,
      limit: limit,
      metadata: metadata,
    );
  }

  Future<CursorPageResult<StudySet>> _processPagingRemoteMediator({
    required bool forceRefresh,
    required bool isCacheExpired,
    required DateTime now,
    required StudySetPagingEnum key,
    required int limit,
    StudySetPagingMetadata? metadata,
  }) async {
    if (limit < 1) throw Exception("limit must bigger than 0");

    //Nếu force refresh hoặc cache bị hết hạn thì ta clear key của metadata đó đi
    bool isReset = false;
    if (forceRefresh || isCacheExpired) {
      await _local.clearStudySetsMetadataByCateKeyAndStudySets(key);
      isReset = true;
    }

    CursorPageResult<StudySet> result;
    //Nếu metadata chưa có hoặc nextCursorId của metadata vẫn còn
    //khác null thì ta sẽ gọi lên Server kéo dữ liệu về
    if (metadata == null || metadata.nextCursorId != null) {
      //Trong trường hợp forceRefresh = true thì ta cho requestCursor = null,
      //còn nếu false thì ta kiểm tra nếu dữ liệu trước đó đã bị reset thì
      //ta sẽ lấy cursor là null, tránh việc lấy cursorId từ metadata cũ đã bị reset.
      final requestCursor = forceRefresh
          ? null
          : isReset
          ? null
          : metadata?.nextCursorId;

      result = await _remote.fetchStudySets(
        limit: limit,
        cursor: requestCursor,
      );

      await _local.addOrUpdateStudySetMetadata(
        StudySetPagingMetadata(
          categoryKey: key.name,
          lastUpdatedAt: now,
          nextCursorId: result.items.length == limit
              ? result.items[result.items.length - 1].id
              : null,
        ),
      );

      await _local.saveStudySets(result.items);
    } else {
      //Nếu không ta trả về mảng rỗng
      result = CursorPageResult(items: [], hasNextPage: null);
    }

    return result;
  }

  ///Hàm này xử lí load cục bộ, không thực hiện ghi dữ liệu vào
  ///metadata hay lưu dữ liệu từ server về local.
  Future<CursorPageResult<StudySet>> _processPagingLocal({
    required int limit,
    required DateTime now,
    String? nextCursorId,
    required StudySetPagingEnum key,
    required bool isFullSync,
  }) async {
    final items = await _local.getStudySetsPaging(
      limit: limit,
      nextCursorId: nextCursorId,
    );
    String? nextCId = null;
    if (items.length > 0) {
      nextCId = items[items.length - 1].id;
    }

    final result = CursorPageResult(
      items: items,
      //Logic này đảm bảo tránh việc dữ liệu từ Server
      //vẫn còn nhưng trong 1 khoảng việc lấy data từ local
      //bị miss 1 số item khiến UI không còn tiếp tục cuộn nữa
      hasNextPage: isFullSync ? limit == items.length : true,
      nextCursorId: nextCId,
      nextCursorUpdatedAt: now,
    );

    return result;
  }
}
