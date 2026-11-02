import '../../../../core/services/api/api_client.dart';

class AuthRemoteSource {
  final ApiClient api;
  AuthRemoteSource(this.api);
  Future<dynamic> login([Map<String, dynamic>? data]) =>
      api.call('/auth/login', data: data, post: true);
  Future<dynamic> logout([Map<String, dynamic>? data]) =>
      api.call('/auth/logout', data: data, post: true);
}
