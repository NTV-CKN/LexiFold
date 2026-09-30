import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/features/main/library/screens/crud_study_set/form_state_provider.dart';
import 'package:lexifold/main.dart';
import 'package:lexifold/providers/auth/auth_provider.dart';
import 'package:lexifold/providers/core/local_db/lexi_fold_db_provider.dart';
import 'package:lexifold/providers/sync_manager/sync_manager.dart';
import 'package:lexifold/utils/routes_name.dart';

final List<ProviderOrFamily> userDataProvidersToCleanup = [
  authNotifierProvider,
  studySetFormStateProvider,
  syncManagerProvider,
];

class CleanSignOutNotifier extends Notifier<void> {
  @override
  void build() {}

  /**
   * Phương thức này sẽ thực hiện điều hướng màn hình
   * về trang chủ khi được gọi, đồng thời tiến hành 'Invalidate'
   * các provider cũ để đảm bảo sau khi thoát phiên sẽ không
   * giữ lại các dữ liệu của người dùng trước đó.
   */
  Future<void> performCleanSignOut() async {
    try {
      await ref.read(lexifoldDbProvider).clearAllTables();
      for (ProviderOrFamily item in userDataProvidersToCleanup) {
        ref.invalidate(item);
      }
    } catch (e) {
      debugPrint("Lỗi khi đăng xuất: $e");
    } finally {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        RoutesName.authScreen,
        (route) => false,
      );
    }
  }
}

final cleanSignOutProvider =
    NotifierProvider<CleanSignOutNotifier, void>(
      CleanSignOutNotifier.new,
    );
