import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../data_sources/messaging_remote_source.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingRemoteSource source;
  MessagingRepositoryImpl(this.source);
  @override
  Future<Either<Failure, dynamic>> list([Map<String, dynamic>? data]) async =>
      await source.list(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> send([Map<String, dynamic>? data]) async =>
      await source.send(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> directory([
    Map<String, dynamic>? data,
  ]) async => await source.directory(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> markRead([
    Map<String, dynamic>? data,
  ]) async => await source.markRead(data) as Either<Failure, dynamic>;
}
