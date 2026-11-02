import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/leave_repository.dart';
import '../data_sources/leave_remote_source.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteSource source;
  LeaveRepositoryImpl(this.source);
  @override
  Future<Either<Failure, dynamic>> list([Map<String, dynamic>? data]) async =>
      await source.list(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> request([
    Map<String, dynamic>? data,
  ]) async => await source.request(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> inbox([Map<String, dynamic>? data]) async =>
      await source.inbox(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> review([Map<String, dynamic>? data]) async =>
      await source.review(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> cancel([Map<String, dynamic>? data]) async =>
      await source.cancel(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> balance([
    Map<String, dynamic>? data,
  ]) async => await source.balance(data) as Either<Failure, dynamic>;
}
