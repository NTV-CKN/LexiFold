import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/providers/core/api_client_provider.dart';
import 'package:lexifold/providers/core/firebase_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseAuth = ref.read(firebaseAuthProvider);
    final user = firebaseAuth.currentUser;

    return Center(
      child: FutureBuilder<String?>(
        future: user?.getIdToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text("Lỗi lấy token: ${snapshot.error}");
          }

          final token = snapshot.data ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextButton(
                  onPressed: () async {
                    await ref.read(apiClientProvider).performLogout();
                  },
                  child: Text("SignOut"),
                ),
                SizedBox(height: 49),
                TextField(
                  controller: TextEditingController(text: token),
                  readOnly: true,
                  // Chỉ cho xem/coppy, không cho gõ phím
                  maxLines: 6,
                  // Hiển thị nhiều dòng cho dễ nhìn JWT
                  decoration: InputDecoration(
                    labelText: 'JWT ID Token',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: token));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép Token!'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
