import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';

abstract class LeaveRepository {
  Future<Either<Failure, dynamic>> list([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> request([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> inbox([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> review([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> cancel([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> balance([Map<String, dynamic>? data]);
}
