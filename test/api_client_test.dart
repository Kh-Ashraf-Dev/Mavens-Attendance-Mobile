import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavens_attendee/core/services/api/api_client.dart';

class TestAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  TestAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient client;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    client = ApiClient(storage);
  });
  tearDown(() => client.dio.close(force: true));

  test('login uses the public HTTPS API and preserves the /api path', () async {
    client.dio.httpClientAdapter = TestAdapter((options) async {
      expect(
        options.uri.toString(),
        'https://mavens-attendance-test-khashraf.fly.dev/api/auth/login',
      );
      expect(options.method, 'POST');
      expect(options.headers.containsKey('X-Device-Id'), isFalse);
      expect(options.receiveTimeout, const Duration(seconds: 90));
      return ResponseBody.fromString(
        '{"message":"Invalid email or password."}',
        401,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    final result = await client.call(
      '/auth/login',
      post: true,
      data: {'email': 'test@example.com'},
    );
    result.fold((failure) {
      expect(failure.status, 401);
      expect(failure.message, 'Invalid email or password.');
    }, (_) => fail('Expected the server validation error.'));
  });

  test(
    'a sleeping-server proxy response gives an actionable error without retrying a POST',
    () async {
      var calls = 0;
      client.dio.httpClientAdapter = TestAdapter((_) async {
        calls++;
        return ResponseBody.fromString('<html>Starting</html>', 502);
      });
      final result = await client.call(
        '/leave',
        post: true,
        data: {'type': 'REGULAR'},
      );
      result.fold((failure) {
        expect(failure.status, 502);
        expect(failure.message, contains('taking longer to respond'));
      }, (_) => fail('Expected the temporary server error.'));
      expect(
        calls,
        1,
        reason: 'A leave request must never be automatically duplicated.',
      );
    },
  );

  test(
    'a cold-start timeout is distinguished from loss of connectivity',
    () async {
      client.dio.httpClientAdapter = TestAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      });
      final result = await client.call('/health');
      result.fold(
        (failure) => expect(failure.message, contains('try again shortly')),
        (_) => fail('Expected a timeout message.'),
      );
    },
  );

  test('certificate failures do not disable certificate validation', () async {
    client.dio.httpClientAdapter = TestAdapter((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badCertificate,
      );
    });
    final result = await client.call('/health');
    result.fold(
      (failure) => expect(failure.message, contains('secure connection')),
      (_) => fail('Expected the TLS error to be preserved.'),
    );
  });
}
