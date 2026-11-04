import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mavens_attendee/config/theme/app_theme.dart';
import 'package:mavens_attendee/core/errors/failure.dart';
import 'package:mavens_attendee/core/services/locator/service_locator.dart';
import 'package:mavens_attendee/core/widgets/common.dart';
import 'package:mavens_attendee/features/auth/domain/repositories/auth_repository.dart';
import 'package:mavens_attendee/features/auth/presentation/views/screens/login_screen.dart';
import 'package:mavens_attendee/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mavens_attendee/features/attendance/presentation/views/screens/today_screen.dart';
import 'package:mavens_attendee/features/leave/domain/repositories/leave_repository.dart';
import 'package:mavens_attendee/features/leave/presentation/views/screens/leave_screen.dart';

class BlockedAuth implements AuthRepository {
  @override
  Future<Either<Failure, dynamic>> login([Map<String, dynamic>? data]) async =>
      const Left(Failure('Account blocked. Contact your administrator.', 423));
  @override
  Future<Either<Failure, dynamic>> logout([Map<String, dynamic>? data]) async =>
      const Right({});
}

class UnconfiguredAttendance implements AttendanceRepository {
  @override
  Future<Either<Failure, dynamic>> overview([
    Map<String, dynamic>? data,
  ]) async => const Right({
    'user': {'name': 'Nagat'},
    'balance': {'configured': false},
    'attendance': [],
    'today': '2026-11-02',
    'mode': 'UNCONFIGURED',
    'week': [],
    'scheduleConfigured': false,
  });
  @override
  Future<Either<Failure, dynamic>> checkIn([
    Map<String, dynamic>? data,
  ]) async => throw StateError('Unconfigured schedule must never punch');
  @override
  Future<Either<Failure, dynamic>> checkOut([
    Map<String, dynamic>? data,
  ]) async => throw StateError('Unconfigured schedule must never punch');
}

class PendingLeave implements LeaveRepository {
  bool cancelled = false;
  @override
  Future<Either<Failure, dynamic>> list([Map<String, dynamic>? data]) async =>
      Right(
        cancelled
            ? []
            : [
                {
                  'id': 'l1',
                  'type': 'REGULAR',
                  'status': 'PENDING',
                  'startDate': '2026-11-09',
                  'endDate': '2026-11-09',
                  'days': 1,
                  'reason': 'Personal appointment',
                },
              ],
      );
  @override
  Future<Either<Failure, dynamic>> balance([
    Map<String, dynamic>? data,
  ]) async => Right({
    'configured': true,
    'available': cancelled ? 10 : 9,
    'accrued': 12,
    'used': 2,
    'pending': cancelled ? 0 : 1,
  });
  @override
  Future<Either<Failure, dynamic>> cancel([Map<String, dynamic>? data]) async {
    cancelled = true;
    return const Right({});
  }

  @override
  Future<Either<Failure, dynamic>> inbox([Map<String, dynamic>? data]) async =>
      const Right([]);
  @override
  Future<Either<Failure, dynamic>> request([
    Map<String, dynamic>? data,
  ]) async => const Right({});
  @override
  Future<Either<Failure, dynamic>> review([Map<String, dynamic>? data]) async =>
      const Right({});
}

void main() {
  setUp(() async {
    tz.initializeTimeZones();
    await locator.reset();
    FlutterSecureStorage.setMockInitialValues({});
    configureDependencies();
  });
  tearDown(() async {
    await locator.reset();
  });
  test(
    'Attendance times stay in Cairo regardless of device timezone, including DST',
    () {
      expect(timeText('2026-11-02T08:00:00Z'), '10:00 AM');
      expect(dateText('2026-11-02'), '02 Nov 2026');
      expect(timeText('2026-07-02T07:00:00Z'), '10:00 AM');
    },
  );
  testWidgets(
    'A blocked account shows an actionable error and cannot enter the app',
    (tester) async {
      locator.unregister<AuthRepository>();
      locator.registerSingleton<AuthRepository>(BlockedAuth());
      bool signedIn = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: LoginScreen(onLogin: () => signedIn = true),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'nagat@mavens.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.ensureVisible(find.text('Sign in  \u2192'));
      await tester.tap(find.text('Sign in  \u2192'));
      await tester.pumpAndSettle();
      expect(
        find.text('Account blocked. Contact your administrator.'),
        findsOneWidget,
      );
      expect(signedIn, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Unconfigured schedule disables attendance and missing hiring date has no invented number',
    (tester) async {
      locator.unregister<AttendanceRepository>();
      locator.registerSingleton<AttendanceRepository>(UnconfiguredAttendance());
      TodayScreen.cairoHour = () => 11;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: TodayScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Schedule not set'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNull,
      );

      await tester.scrollUntilVisible(
        find.text('Ask Moataz to configure your hiring date'),
        80,
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Ask Moataz to configure your hiring date'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Cancelling pending leave refreshes both requests and available annuals',
    (tester) async {
      locator.unregister<LeaveRepository>();
      locator.registerSingleton<LeaveRepository>(PendingLeave());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: LeaveScreen(
              user: {'id': 'rec', 'role': 'RECRUITER'},
              balance: {'configured': false},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('9.00 days'), findsOneWidget);
      await tester.ensureVisible(find.text('Cancel request'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel request'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('10.00 days'), findsOneWidget);
      expect(find.text('No requests yet'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Punch button is hidden outside 8 AM to 8 PM Cairo time', (
    tester,
  ) async {
    locator.unregister<AttendanceRepository>();
    locator.registerSingleton<AttendanceRepository>(UnconfiguredAttendance());
    TodayScreen.cairoHour = () => 21;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check in'), findsNothing);
    expect(
      find.text(
        'Check-in and check-out are available from 8:00 AM to 8:00 PM.',
      ),
      findsOneWidget,
    );
    TodayScreen.cairoHour = () => 11;
    await tester.pumpWidget(const SizedBox());
  });
}
