import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mavens_attendee/config/environment/environment.dart';
import 'package:mavens_attendee/core/services/api/api_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'physical phone reaches hosted API and receives login validation',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Checking Mavens connection…')),
          ),
        ),
      );
      expect(
        Environment.apiUrl,
        'https://mavens-attendance-test-khashraf.fly.dev/api',
      );
      expect(
        const String.fromEnvironment('API_URL'),
        Environment.apiUrl,
        reason: 'The build must receive the hosted API URL from testing.json.',
      );
      const storage = FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
        ),
      );
      final api = ApiClient(storage);
      try {
        final health = await api.call('/health');
        health.fold(
          (failure) => fail(failure.message),
          (data) => expect(data['status'], 'ok'),
        );
        // An intentionally unknown account verifies native DNS/TLS/routing and
        // the exact login path without enrolling or blocking any real account.
        final login = await api.call(
          '/auth/login',
          post: true,
          data: {
            'email': 'connectivity-check@mavens.invalid',
            'password': 'reachability-check-only',
          },
        );
        login.fold((failure) {
          expect(failure.status, 401);
          expect(failure.message, 'Invalid email or password.');
        }, (_) => fail('The deliberately unknown account must be rejected.'));
      } finally {
        api.dio.close(force: true);
      }
    },
  );
}
