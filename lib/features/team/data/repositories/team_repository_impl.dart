import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/team_repository.dart';
import '../data_sources/team_remote_source.dart';

class TeamRepositoryImpl implements TeamRepository {
  final TeamRemoteSource source;
  TeamRepositoryImpl(this.source);
  @override
  Future<Either<Failure, dynamic>> load([Map<String, dynamic>? data]) async =>
      await source.load(data) as Either<Failure, dynamic>;
}
