import 'package:lexifold/data/source/local/daos/sync_queues/sync_queue_local_source.dart';

import '../source/local/lexi_fold_database.dart';

abstract class SyncQueueRepository {
  Future<void> addSyncQueueTask(SyncQueuesCompanion syncQueue);

  Future<int> getPendingOrErrorCount();

  Future<List<SyncQueue>> getPendingOrErr();

  Future<bool> markDone(SyncQueue syncQueue);

  Future<void> increaseCountRequest(SyncQueue syncQueue);

  Future<void> resetCountRequestAndSyncState();

  Stream<List<SyncQueue>> watchSyncQueuesPendingOrErr();
}

class SyncQueueRepositoryImpl implements SyncQueueRepository {
  final SyncQueueLocalSource _local;

  const SyncQueueRepositoryImpl({required this._local});

  @override
  Future<void> addSyncQueueTask(SyncQueuesCompanion syncQueue) async {
    await _local.addSyncQueueTask(syncQueue);
  }

  @override
  Future<List<SyncQueue>> getPendingOrErr() async {
    return await _local.getPendingOrErr();
  }

  @override
  Future<int> getPendingOrErrorCount() async {
    return await _local.getPendingOrErrorCount();
  }

  @override
  Future<bool> markDone(SyncQueue syncQueue) async {
    return await _local.markDone(syncQueue);
  }

  @override
  Future<void> increaseCountRequest(SyncQueue syncQueue) async {
    await _local.increaseCountRequest(syncQueue);
  }

  @override
  Stream<List<SyncQueue>> watchSyncQueuesPendingOrErr() {
    return _local.watchSyncQueuesPendingOrErr();
  }

  @override
  Future<void> resetCountRequestAndSyncState() async {
    await _local.resetCountRequestAndSyncState();
  }
}
