import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config/environment/environment.dart';
import '../../errors/failure.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage storage;
  ApiClient(this.storage)
    : dio = Dio(
        BaseOptions(
          baseUrl: Environment.apiUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          final token = await storage.read(key: 'token');
          if (token != null) o.headers['Authorization'] = 'Bearer $token';
          h.next(o);
        },
      ),
    );
  }
  Future<Either<Failure, dynamic>> call(
    String path, {
    Object? data,
    bool post = false,
  }) async {
    try {
      final r = await dio.request(
        path,
        data: data,
        options: Options(method: post ? 'POST' : 'GET'),
      );
      return Right(r.data);
    } on DioException catch (e) {
      final d = e.response?.data;
      return Left(Failure(_errorMessage(e, d), e.response?.statusCode));
    } catch (_) {
      return const Left(Failure('Unable to access secure device storage.'));
    }
  }

  static String _errorMessage(DioException error, dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if ([502, 503, 504].contains(error.response?.statusCode) ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Mavens is taking longer to respond. Please try again shortly.';
    }
    if (error.type == DioExceptionType.badCertificate) {
      return 'Could not establish a secure connection to Mavens.';
    }
    if (error.type == DioExceptionType.badResponse) {
      return 'Mavens could not complete this request. Please try again.';
    }
    return 'Unable to reach Mavens. Check your connection.';
  }
}
