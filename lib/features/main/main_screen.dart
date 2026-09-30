import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/features/main/home/home_screen.dart';
import 'package:lexifold/features/main/library/library_screen.dart';
import 'package:lexifold/features/main/main_screen_provider.dart';
import 'package:lexifold/l10n/app_localizations.dart';
import 'package:lexifold/providers/clean_signout/clean_signout_provider.dart';
import 'package:lexifold/providers/core/api_client_provider.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected
        ? const Color(0xFF635BFF)
        : Colors.grey.shade500;

    return InkWell(
      onTap: () =>
          ref.read(tabMainBottomNavProvider.notifier).state = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, color: color, size: 40)],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleanProvider = ref.read(cleanSignOutProvider.notifier);
    final apiClient = ref.read(apiClientProvider);
    //Thiết lập logic quay về màn hình đăng nhập khi token hết hiệu lực
    apiClient.setOnLogoutListener(() async {
      await cleanProvider.performCleanSignOut();
    });

    final currentIndex = ref.watch(tabMainBottomNavProvider);

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final screens = const [HomeScreen(), LibraryScreen()];

    return Scaffold(
      //content
      body: IndexedStack(children: screens, index: currentIndex),

      //FAB scan
      floatingActionButton: Padding(
        padding: EdgeInsets.only(top: 27),
        child: FloatingActionButton(
          onPressed: () {},
          shape: const CircleBorder(),
          backgroundColor: colorScheme.primary,
          elevation: 3,
          child: Icon(
            Icons.document_scanner_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      //Bottom nav
      bottomNavigationBar: BottomAppBar(
        notchMargin: 20.0,
        clipBehavior: Clip.antiAlias,
        shape: const CircularNotchedRectangle(),
        child: Row(
          children: [
            //home
            const Spacer(flex: 1),
            _buildNavItem(
              context,
              ref,
              icon: Icons.home_outlined,
              label: l10n.textHome,
              index: 0,
              currentIndex: currentIndex,
            ),

            //scan
            const Spacer(flex: 3),

            //library
            _buildNavItem(
              context,
              ref,
              icon: Icons.folder_copy_outlined,
              label: l10n.textLibrary,
              index: 1,
              currentIndex: currentIndex,
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
