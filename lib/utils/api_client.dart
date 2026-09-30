import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiClient {
  late final Dio _dio;
  final FirebaseAuth _firebaseAuth;
  Future<void> Function()? _onLogout;

  ApiClient({
    required this._firebaseAuth,
    required String baseUrl,
    this._onLogout,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 50),
        receiveTimeout: const Duration(seconds: 50),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _initializeDio();
  }

  void _initializeDio() {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (option, handler) async {
          final idToken = await _firebaseAuth.currentUser
              ?.getIdToken();
          if (idToken != null) {
            option.headers["Authorization"] = "Bearer $idToken";
          }

          //Tạo mới request để tiếp tục gọi mạng
          handler.next(option);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          if (statusCode != null && statusCode == 401) {
            final isRetried =
                error.requestOptions.extra["isRetried"] ?? false;
            //Nếu request trước đó chưa retry và dính lỗi 401 => Ta đi refresh jwt mới
            if (!isRetried) {
              error.requestOptions.extra["isRetried"] = true;

              try {
                final newIdToken = await _retryRefreshToken();
                if (newIdToken == null) {
                  await performLogout();
                } else {
                  error.requestOptions.headers["Authorization"] =
                      "Bearer $newIdToken";

                  final clonedResponse = await _dio.fetch(
                    error.requestOptions,
                  );

                  return handler.resolve(clonedResponse);
                }
              } catch (err) {
                await performLogout();
              }
            }
            //Nếu đã retry mà dính lỗi 401 => logout để tránh lặp vô tận
            else {
              await performLogout();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  void setOnLogoutListener(Future<void> Function() onLogout) {
    this._onLogout = onLogout;
  }

  //Đoạn phương thức này gọi lệnh refresh đểlàm mới jwt (access) từ FirebsaeAuth
  Future<String?> _retryRefreshToken() async {
    try {
      //Yêu cầu firebase cấp jwt mới từ máy chủ
      final newIdToken = await _firebaseAuth.currentUser?.getIdToken(
        true,
      );

      return newIdToken;
    } catch (err) {
      return null;
    }
  }

  Future<void> performLogout() async {
    await _firebaseAuth.signOut();
    await _onLogout?.call();
  }

  //Giúp các source remote gọi nhanh
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }
}
