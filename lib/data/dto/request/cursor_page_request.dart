class CursorPageRequest {
  final int limit;
  final String? lastId;
  final Map<String, dynamic> filters;

  CursorPageRequest({
    this.limit = 20,
    this.lastId,
    this.filters = const {},
  });

  Map<String, dynamic> toJson() {
    return {"limit": limit, "lastId": lastId, "filters": filters};
  }
}
