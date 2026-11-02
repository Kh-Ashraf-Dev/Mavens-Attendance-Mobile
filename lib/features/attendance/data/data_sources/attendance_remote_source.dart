import '../../../../core/services/api/api_client.dart';

class AttendanceRemoteSource {
  final ApiClient api;
  AttendanceRemoteSource(this.api);
  Future<dynamic> overview([Map<String, dynamic>? data]) =>
      api.call('/overview', data: data, post: false);
  Future<dynamic> checkIn([Map<String, dynamic>? data]) =>
      api.call('/attendance/check-in', data: data, post: true);
  Future<dynamic> checkOut([Map<String, dynamic>? data]) =>
      api.call('/attendance/check-out', data: data, post: true);
}
