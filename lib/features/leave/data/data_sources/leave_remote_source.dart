import '../../../../core/services/api/api_client.dart';

class LeaveRemoteSource {
  final ApiClient api;
  LeaveRemoteSource(this.api);
  Future<dynamic> list([Map<String, dynamic>? data]) =>
      api.call('/leave', data: data, post: false);
  Future<dynamic> request([Map<String, dynamic>? data]) =>
      api.call('/leave', data: data, post: true);
  Future<dynamic> inbox([Map<String, dynamic>? data]) =>
      api.call('/leave/inbox', data: data, post: false);
  Future<dynamic> review([Map<String, dynamic>? data]) =>
      api.call('/leave/${data!['id']}/review', data: data, post: true);
  Future<dynamic> cancel([Map<String, dynamic>? data]) =>
      api.call('/leave/${data!['id']}/cancel', data: data, post: true);
  Future<dynamic> balance([Map<String, dynamic>? data]) =>
      api.call('/leave/balance');
}
