import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../location_service.dart';
import '../../../features/auth/data/data_sources/auth_remote_source.dart';
import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../features/auth/domain/use_cases/auth_actions.dart';
import '../../../features/auth/presentation/view_model/auth_cubit.dart';
import '../../../features/attendance/data/data_sources/attendance_remote_source.dart';
import '../../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../../features/attendance/domain/use_cases/attendance_actions.dart';
import '../../../features/attendance/presentation/view_model/attendance_cubit.dart';
import '../../../features/leave/data/data_sources/leave_remote_source.dart';
import '../../../features/leave/data/repositories/leave_repository_impl.dart';
import '../../../features/leave/domain/repositories/leave_repository.dart';
import '../../../features/leave/domain/use_cases/leave_actions.dart';
import '../../../features/leave/presentation/view_model/leave_cubit.dart';
import '../../../features/messaging/data/data_sources/messaging_remote_source.dart';
import '../../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../../features/messaging/domain/use_cases/messaging_actions.dart';
import '../../../features/messaging/presentation/view_model/messaging_cubit.dart';
import '../../../features/team/data/data_sources/team_remote_source.dart';
import '../../../features/team/data/repositories/team_repository_impl.dart';
import '../../../features/team/domain/repositories/team_repository.dart';
import '../../../features/team/domain/use_cases/team_actions.dart';
import '../../../features/team/presentation/view_model/team_cubit.dart';

final locator = GetIt.instance;
void configureDependencies() {
  locator.registerLazySingleton(
    () => const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    ),
  );
  locator.registerLazySingleton(() => ApiClient(locator()));
  locator.registerLazySingleton(() => LocationService());
  locator.registerLazySingleton(() => AuthRemoteSource(locator()));
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(locator()),
  );
  locator.registerLazySingleton(() => AuthActions(locator()));
  locator.registerFactory(() => AuthCubit(locator()));
  locator.registerLazySingleton(() => AttendanceRemoteSource(locator()));
  locator.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(locator()),
  );
  locator.registerLazySingleton(() => AttendanceActions(locator()));
  locator.registerFactory(() => AttendanceCubit(locator()));
  locator.registerLazySingleton(() => LeaveRemoteSource(locator()));
  locator.registerLazySingleton<LeaveRepository>(
    () => LeaveRepositoryImpl(locator()),
  );
  locator.registerLazySingleton(() => LeaveActions(locator()));
  locator.registerFactory(() => LeaveCubit(locator()));
  locator.registerLazySingleton(() => MessagingRemoteSource(locator()));
  locator.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(locator()),
  );
  locator.registerLazySingleton(() => MessagingActions(locator()));
  locator.registerFactory(() => MessagingCubit(locator()));
  locator.registerLazySingleton(() => TeamRemoteSource(locator()));
  locator.registerLazySingleton<TeamRepository>(
    () => TeamRepositoryImpl(locator()),
  );
  locator.registerLazySingleton(() => TeamActions(locator()));
  locator.registerFactory(() => TeamCubit(locator()));
}
