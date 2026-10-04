import 'package:lexifold/data/model/base_class_dto.dart';

class CursorPageResult<T extends BaseClassDto> {
  final List<T> items;
  final String? nextCursorId;
  final DateTime? nextCursorUpdatedAt;
  final bool? hasNextPage;

  CursorPageResult({
    required this.items,
    this.nextCursorId,
    this.nextCursorUpdatedAt,
    required this.hasNextPage,
  });

  CursorPageResult copyWith({
    List<T>? items,
    String? nextCursorId,
    DateTime? nextCursorUpdatedAt,
    bool? hasNextPage = null,
  }) {
    return CursorPageResult(
      items: items ?? this.items,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      nextCursorId: nextCursorId,
      nextCursorUpdatedAt: nextCursorUpdatedAt,
    );
  }

  factory CursorPageResult.fromJson(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    List<dynamic> items = (map["items"] as List<dynamic>?) ?? [];

    return CursorPageResult(
      items: items
          .cast<Map<String, dynamic>>()
          .map((item) => fromJson(item))
          .toList(),
      hasNextPage: map["hasNextPage"],
      nextCursorId: map["nextCursorId"],
    );
  }
}
