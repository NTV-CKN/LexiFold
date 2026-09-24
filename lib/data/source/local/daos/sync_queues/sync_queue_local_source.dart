import 'package:lexifold/data/source/local/daos/sync_queues/sync_queues_dao.dart';

import '../../lexi_fold_database.dart';

abstract class SyncQueueLocalSource {
  Future<void> addSyncQueueTask(SyncQueuesCompanion syncQueue);

  Future<int> getPendingOrErrorCount();

  Future<List<SyncQueue>> getPendingOrErr();

  Future<bool> markDone(SyncQueue syncQueue);

  Future<void> increaseCountRequest(SyncQueue syncQueue);

  Future<void> resetCountRequestAndSyncState();

  Stream<List<SyncQueue>> watchSyncQueuesPendingOrErr();
}

class SyncQueueLocalSourceImpl implements SyncQueueLocalSource {
  final SyncQueuesDao _syncQueuesDao;

  const SyncQueueLocalSourceImpl({required this._syncQueuesDao});

  @override
  Future<void> addSyncQueueTask(SyncQueuesCompanion syncQueue) async {
    await _syncQueuesDao.addSyncQueueTask(syncQueue);
  }

  @override
  Future<List<SyncQueue>> getPendingOrErr() async {
    return await _syncQueuesDao.getPendingOrErr();
  }

  @override
  Future<int> getPendingOrErrorCount() async {
    return await _syncQueuesDao.getPendingOrErrorCount();
  }

  @override
  Future<bool> markDone(SyncQueue syncQueue) async {
    return await _syncQueuesDao.markDone(syncQueue);
  }

  @override
  Future<void> increaseCountRequest(SyncQueue syncQueue) async {
    await _syncQueuesDao.increaseCountRequest(syncQueue);
  }

  @override
  Stream<List<SyncQueue>> watchSyncQueuesPendingOrErr() {
    return _syncQueuesDao.watchSyncQueuesPendingOrErr();
  }

  @override
  Future<void> resetCountRequestAndSyncState() async {
    await _syncQueuesDao.resetCountRequestAndSyncState();
  }
}
