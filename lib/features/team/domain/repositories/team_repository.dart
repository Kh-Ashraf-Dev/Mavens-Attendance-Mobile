import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';

abstract class TeamRepository {
  Future<Either<Failure, dynamic>> load([Map<String, dynamic>? data]);
}
