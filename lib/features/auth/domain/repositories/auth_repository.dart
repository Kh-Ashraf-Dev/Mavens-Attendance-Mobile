import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, dynamic>> login([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> logout([Map<String, dynamic>? data]);
}
