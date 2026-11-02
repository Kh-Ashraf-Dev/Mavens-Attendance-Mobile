import '../../../../core/services/api/api_client.dart';

class MessagingRemoteSource {
  final ApiClient api;
  MessagingRemoteSource(this.api);
  Future<dynamic> list([Map<String, dynamic>? data]) =>
      api.call('/messages', data: data, post: false);
  Future<dynamic> send([Map<String, dynamic>? data]) =>
      api.call('/messages', data: data, post: true);
  Future<dynamic> directory([Map<String, dynamic>? data]) =>
      api.call('/directory', data: data, post: false);
  Future<dynamic> markRead([Map<String, dynamic>? data]) =>
      api.call('/messages/${data!['id']}/read', data: data, post: true);
}
