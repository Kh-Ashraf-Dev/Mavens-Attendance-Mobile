import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource source;
  AuthRepositoryImpl(this.source);
  @override
  Future<Either<Failure, dynamic>> login([Map<String, dynamic>? data]) async =>
      await source.login(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> logout([Map<String, dynamic>? data]) async =>
      await source.logout(data) as Either<Failure, dynamic>;
}
