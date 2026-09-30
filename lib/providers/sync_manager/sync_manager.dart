import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/data/enums/sync_option.dart';
import 'package:lexifold/providers/core/local_db/lexi_fold_db_provider.dart';
import 'package:lexifold/providers/core/network/network_info_provider.dart';
import 'package:lexifold/providers/study_sets/study_sets_core_provider.dart';
import 'package:lexifold/providers/sync_manager/sync_queue_core_provider.dart';

import '../../data/source/local/lexi_fold_database.dart';

class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final String? lastErr;
  final DateTime? lastSyncAt;

  const SyncState({
    required this.isSyncing,
    required this.pendingCount,
    required this.lastErr,
    required this.lastSyncAt,
  });

  factory SyncState.initial() {
    return const SyncState(
      isSyncing: false,
      pendingCount: 0,
      lastErr: null,
      lastSyncAt: null,
    );
  }

  SyncState copyWith({
    bool? isSync,
    int? pendingCount,
    String? lastErr,
    DateTime? lastSyncAt,
  }) {
    return SyncState(
      isSyncing: isSync ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastErr: lastErr ?? this.lastErr,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

class SyncManagerNotifier extends AsyncNotifier<SyncState?> {
  StreamSubscription<List<SyncQueue>>? _queueTasks;
  bool _isDisposed = false;
  bool _isBusy = false; //Hạn chế độ trễ, tránh chồng chéo request

  @override
  FutureOr<SyncState?> build() async {
    _listenNetworkState();
    _listenQueueTasks();

    ref.onDispose(() {
      _isDisposed = true;
      _queueTasks?.cancel();
    });

    final syncQueueRepository = ref.read(syncQueueRepositoryProvider);

    //Khôi phục các record có thời gian lỗi cuối lớn hơn 5 tiếng
    await syncQueueRepository.resetCountRequestAndSyncState();

    final count = await syncQueueRepository.getPendingOrErrorCount();
    if (count > 0) {
      unawaited(_trySyncNow());
    }

    return SyncState.initial().copyWith(pendingCount: count);
  }

  _listenNetworkState() {
    ref.listen(networkStatusProvider, (prev, next) {
      next.whenData((results) {
        final hasConnection = results.any(
          (result) =>
              result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.ethernet ||
              result == ConnectivityResult.vpn,
        );

        if (hasConnection && !_isDisposed) {
          if (!_isDisposed) unawaited(_trySyncNow());
        }
      });
    });
  }

  _listenQueueTasks() {
    _queueTasks?.cancel();
    final syncQueueRepository = ref.read(syncQueueRepositoryProvider);
    _queueTasks = syncQueueRepository
        .watchSyncQueuesPendingOrErr()
        .listen((queueTasks) async {
          if (queueTasks.isNotEmpty) {
            unawaited(_trySyncNow());
          }
        });
  }

  ///Hàm này khi được gọi sẽ kiểm tra các trạng thái khả thi trước khi đồng bộ
  ///dữ liệu lên server.
  ///
  ///Nếu đủ điều kiện thực thi, nó sẽ đi xuống lấy ra các dữ liệu đang chờ đồng
  ///bộ hoặc đồng bộ nhưng bị lỗi để thực hiện công việc.
  _trySyncNow() async {
    //Nếu đang trong quá trình đồng bộ thì đợi lượt sau
    if (_isBusy) return;
    _isBusy = true;

    final syncState = state.valueOrNull ?? SyncState.initial();
    //Nếu mạng thật sự có kết nối ra Internet thì mới thực hiện tiếp
    final isRealInternet = await ref.read(
      realInternetCheckerProvider,
    )();

    if (!isRealInternet) return;

    final syncQueueRepository = ref.read(syncQueueRepositoryProvider);
    final pendingOrErrCount = await syncQueueRepository
        .getPendingOrErrorCount();

    if (pendingOrErrCount == 0) {
      state = AsyncData(
        syncState.copyWith(isSync: false, pendingCount: 0),
      );
      _isBusy = false;
      return;
    }

    state = AsyncData(
      syncState.copyWith(
        isSync: true,
        pendingCount: pendingOrErrCount,
      ),
    );

    String lastErr = "";

    try {
      final syncQueues = await syncQueueRepository.getPendingOrErr();

      for (SyncQueue item in syncQueues) {
        bool isIncreaseCountReq = false;
        try {
          final result = await _pushItem(item);
          if (result) {
            await syncQueueRepository.markDone(item);
          } else {
            await syncQueueRepository.increaseCountRequest(item);
            isIncreaseCountReq = true;
          }
        } catch (e) {
          lastErr = e.toString();
          print("Err: $lastErr");
          if (!isIncreaseCountReq)
            await syncQueueRepository.increaseCountRequest(item);
        }
      }
    } catch (e) {
      lastErr = e.toString();
    } finally {
      _isBusy = false;
      final pendingOrErrCount = await syncQueueRepository
          .getPendingOrErrorCount();

      state = AsyncData(
        syncState.copyWith(
          isSync: false,
          pendingCount: pendingOrErrCount,
        ),
      );

      //Nếu vẫn còn task thì nó tiếp tục chạy để tránh nuốt task
      // if (pendingOrErrCount > 0) {
      //   await Future.delayed(Duration(seconds: 2), () {
      //     if (!_isDisposed) unawaited(_trySyncNow());
      //   });
      // }
    }
  }

  ///Hàm này sẽ xử lí việc bóc tách các thông tin trong syncQueue để
  ///xác định nên gọi logic đồng bộ server của Repository nào.
  ///
  /// Trả về true nếu đồng bộ diễn ra thành công, giúp xóa đi đối tượng
  /// này khỏi cơ sở dữ liệu cục bộ.
  ///
  /// Trả về false nếu đồng bộ không thành và sẽ đánh dấu
  /// đối tượng này đồng bộ thất bại và tăng request count lên 1 đơn vị
  Future<bool> _pushItem(SyncQueue syncQueue) async {
    if (syncQueue.entityType == EntitySyncType.study_sets.name) {
      bool? isUpdate = _isSyncQueuePendingUpdate(syncQueue);
      if (isUpdate == null)
        throw Exception(
          "Not support SyncOption: ${syncQueue.syncQueueOption}",
        );

      final baseResult = await ref
          .read(studySetsRepositoryProvider)
          .addOrUpdateStudySetsToServer(isUpdate, syncQueue.payload);

      return baseResult.success;
    }

    return throw Exception(
      "Not support EntityType: ${syncQueue.entityType}",
    );
  }

  bool? _isSyncQueuePendingUpdate(SyncQueue sync) {
    if (sync.syncQueueOption == SyncOption.pending_created.typeName) {
      return false;
    } else if (sync.syncQueueOption ==
        SyncOption.pending_updated.typeName) {
      return true;
    }

    return null;
  }
}

final syncManagerProvider =
    AsyncNotifierProvider<SyncManagerNotifier, SyncState?>(
      SyncManagerNotifier.new,
    );
