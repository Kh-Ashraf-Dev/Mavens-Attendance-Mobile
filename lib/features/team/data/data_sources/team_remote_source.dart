import '../../../../core/services/api/api_client.dart';

class TeamRemoteSource {
  final ApiClient api;
  TeamRemoteSource(this.api);
  Future<dynamic> load([Map<String, dynamic>? data]) =>
      api.call('/team', data: data, post: false);
}
