import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignIn = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

//Provider này lắng nghe trạng thái của đối tượng user trong FirebaseAuth để
//chuyển hướng người dùng sang màn hình trang chủ hoặc đăng nhập.
final authStateProvider = StreamProvider((ref) {
  final firebaseAuth = ref.read(firebaseAuthProvider);

  //Tạo hot stream nghe sự thay đổi của user
  return firebaseAuth.authStateChanges();
});
