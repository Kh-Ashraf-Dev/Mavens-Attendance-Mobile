import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/team_repository.dart';

class TeamActions {
  final TeamRepository repository;
  TeamActions(this.repository);
  Future<Either<Failure, dynamic>> load([Map<String, dynamic>? data]) =>
      repository.load(data);
}
