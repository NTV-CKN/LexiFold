import 'package:drift/drift.dart';
import 'package:lexifold/data/enums/sync_option.dart';

import '../../../../entities/sync_queues.dart';
import '../../lexi_fold_database.dart';

part 'sync_queues_dao.g.dart';

@DriftAccessor(tables: const [SyncQueues])
class SyncQueuesDao extends DatabaseAccessor<LexiFoldDatabase>
    with _$SyncQueuesDaoMixin {
  SyncQueuesDao(LexiFoldDatabase db) : super(db);

  Future<void> addSyncQueueTask(SyncQueuesCompanion syncQueue) async {
    await into(syncQueues).insert(syncQueue);
  }

  ///Hàm này sẽ đếm số lượng các record có trạng thái là Pending hoặc
  ///Error (tức request bị lỗi) với điều kiện requestCount phải nhỏ hơn
  ///5 để tránh lặp vô tận tại SyncManager.
  Future<int> getPendingOrErrorCount() async {
    final countExpr = syncQueues.id.count();

    final query = selectOnly(syncQueues)
      ..addColumns([countExpr])
      ..where(
        syncQueues.syncState.equals(SyncState.pending.name) |
            (syncQueues.syncState.equals(SyncState.failed.name) &
                syncQueues.countRequest.isSmallerOrEqual(
                  const Constant(4),
                )),
      );

    final result = await query.getSingle();
    return result.read(countExpr) ?? 0;
  }

  ///Hàm này lấy ra các record có trạng thái đồng bộ (syncState) là pending hoặc
  ///bị lỗi (với điều kiện số lần đã request không được vượt 4 lần).
  Future<List<SyncQueue>> getPendingOrErr() async {
    final query = select(syncQueues)
      ..where(
        (tbl) =>
            tbl.syncState.equals(SyncState.pending.name) |
            (tbl.syncState.equals(SyncState.failed.name) &
                tbl.countRequest.isSmallerOrEqual(const Constant(4))),
      );

    return await query.get();
  }

  ///Hàm này có nhiệm vụ xóa đi record được chỉ định, được sử dụng
  ///khi việc đồng bộ cho record đó thành công và xóa đi dữ liệu cục bộ
  ///giúp giảm thiểu lưu trữ trên thiết bị người dùng.
  Future<bool> markDone(SyncQueue syncQueue) async {
    final result = await delete(syncQueues).delete(syncQueue);

    return result > 0;
  }

  ///Hàm này sẽ đánh dấu record của SyncQueue với cột
  ///syncState là failed (tức đồng bồ thất bại), tăng countRequest
  ///lên 1 đơn vị và cập nhật lại thời gian thất bại mới nhất.
  Future<void> increaseCountRequest(SyncQueue syncQueue) async {
    await update(syncQueues)
      ..where((tbl) => tbl.id.equals(syncQueue.id))
      ..write(
        SyncQueuesCompanion(
          syncState: Value(SyncState.failed.name),
          countRequest: Value(syncQueue.countRequest + 1),
          lastRequestFailedAt: Value(DateTime.now()),
        ),
      );
  }

  ///Hàm này tiến hành đăng kí lắng nghe bảng SyncQueues
  ///
  /// Khi có biến động nó sẽ lọc các record có syncState là Pending hoặc
  /// Failed với countRequest không vượt quá 4.
  Stream<List<SyncQueue>> watchSyncQueuesPendingOrErr() {
    final query = select(syncQueues)
      ..where(
        (tbl) =>
            tbl.syncState.equals(SyncState.pending.name) |
            (tbl.syncState.equals(SyncState.failed.name) &
                tbl.countRequest.isSmallerOrEqual(const Constant(4))),
      );

    return query.watch();
  }

  ///Hàm này sẽ reset các record có trạng thái syncState Failed với request count là 5
  ///trở lên và thời gian cuối cùng request thất bại phải trên 5 tiếng.
  Future<void> resetCountRequestAndSyncState() async {
    final dateNowSubtract5h = DateTime.now().subtract(
      const Duration(hours: 5),
    );

    await (update(syncQueues)..where(
          (tbl) =>
              tbl.countRequest.isBiggerOrEqual(const Constant(5)) &
              tbl.syncState.equals(SyncState.failed.name) &
              tbl.lastRequestFailedAt.isNotNull() &
              tbl.lastRequestFailedAt.isSmallerOrEqualValue(
                dateNowSubtract5h,
              ),
        ))
        .write(
          SyncQueuesCompanion(
            syncState: Value(SyncState.pending.name),
            countRequest: Value(0),
            lastRequestFailedAt: Value(null),
          ),
        );
  }
}
