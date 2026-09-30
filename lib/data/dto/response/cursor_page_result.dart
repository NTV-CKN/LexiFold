class CursorPageResult<T> {
  final List<T> items;
  final String? nextCursorId;
  final DateTime? nextCursorUpdatedAt;
  final bool hasNextPage;

  CursorPageResult({
    required this.items,
    this.nextCursorId,
    this.nextCursorUpdatedAt,
    required this.hasNextPage,
  });
}
