import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mavens_attendee/core/services/biometric_service.dart';
import 'package:mavens_attendee/core/widgets/welcome_splash.dart';
import 'package:mavens_attendee/config/theme/app_theme.dart';

class FakeAuthentication implements LocalAuthentication {
  bool enrolled = true, accepted = true;
  int prompts = 0;
  @override
  Future<bool> get canCheckBiometrics async => true;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async =>
      enrolled ? [BiometricType.fingerprint] : [];
  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    expect(biometricOnly, isTrue);
    prompts++;
    return accepted;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'Every check-in and checkout requests fresh biometric verification',
    () async {
      final auth = FakeAuthentication();
      final service = BiometricService(authentication: auth);
      await service.verify(false);
      await service.verify(true);
      expect(auth.prompts, 2);
    },
  );
  test('Cancellation and missing biometrics block attendance', () async {
    final auth = FakeAuthentication()..accepted = false;
    final service = BiometricService(authentication: auth);
    await expectLater(service.verify(false), throwsException);
    auth.enrolled = false;
    await expectLater(service.verify(true), throwsException);
    expect(auth.prompts, 1);
  });
  testWidgets('Welcome animation shows the brand then completes once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var complete = 0;
    final boundary = GlobalKey();
    await tester.runAsync(() async {
      final font = FontLoader('Montserrat')
        ..addFont(rootBundle.load('assets/fonts/Montserrat.ttf'));
      await font.load();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RepaintBoundary(
          key: boundary,
          child: WelcomeSplash(onComplete: () => complete++),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/mavens-logo-white.png'),
        boundary.currentContext!,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Welcome Mavens Team'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(complete, 0);
    if (Platform.environment['CAPTURE_SPLASH'] == '1') {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../docs/welcome-splash.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pump(const Duration(milliseconds: 1300));
    expect(complete, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
