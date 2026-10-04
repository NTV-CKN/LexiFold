class ApiEndpoints {
  static const String _version = "/v1";

  static const String loginWithFirebaseAuth =
      "$_version/auth/login-firebase-auth";
  static const String createWithVocabs =
      "$_version/study-set/create-with-vocabs";
  static const String getStudySetsCursor =
      "$_version/study-set/get-items-cursor";
}
