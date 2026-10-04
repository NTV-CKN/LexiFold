import 'package:lexifold/data/dto/request/cursor_page_request.dart';
import 'package:lexifold/data/dto/response/cursor_page_result.dart';
import 'package:lexifold/data/model/result/base_result.dart';
import 'package:lexifold/env/api_endpoints.dart';
import 'package:lexifold/env/env.dart';
import 'package:lexifold/utils/api_client.dart';

import '../local/lexi_fold_database.dart';

abstract class StudySetSourceRemote {
  ///Nhận vào một payload dạng json thể hiện đối tượng
  ///study set và danh sách các vocabularies tương ứng.
  Future<BaseResult> addOrUpdateWithVocabs(
    bool isUpdate,
    String payload,
  );

  Future<CursorPageResult<StudySet>> fetchStudySets({
    required int limit,
    String? cursor,
    Map<String, dynamic>? filters,
  });
}

class StudySetSourceRemoteImpl implements StudySetSourceRemote {
  final ApiClient _apiClient;

  const StudySetSourceRemoteImpl(this._apiClient);

  @override
  Future<BaseResult> addOrUpdateWithVocabs(
    bool isUpdate,
    String payload,
  ) async {
    if (isUpdate)
      return BaseResult(success: false, message: "Chưa hỗ trợ");

    final response = await _apiClient.post(
      "${Env.baseUrl}${ApiEndpoints.createWithVocabs}",
      data: payload,
    );
    final json = response.data;
    if (json == null || json is! Map<String, dynamic>) {
      return BaseResult(
        success: false,
        message: "Data is null or invalid",
      );
    }

    return BaseResult.fromJson(json);
  }

  Future<CursorPageResult<StudySet>> fetchStudySets({
    required int limit,
    String? cursor,
    Map<String, dynamic>? filters,
  }) async {
    final cursorPageRequest = CursorPageRequest(
      limit: limit,
      lastId: cursor,
      filters: filters ?? const {},
    );

    final response = await _apiClient.post(
      "${Env.baseUrl}${ApiEndpoints.getStudySetsCursor}",
      data: cursorPageRequest.toJson(),
    );

    final json = response.data;
    if (json == null || json is! Map<String, dynamic>) {
      throw Exception("response.data is null or not type Map");
    }

    return CursorPageResult<StudySet>.fromJson(
      json,
      (map) => StudySet.fromJson(map),
    );
  }
}
