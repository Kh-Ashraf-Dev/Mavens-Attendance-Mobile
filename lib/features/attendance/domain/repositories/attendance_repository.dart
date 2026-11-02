import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, dynamic>> overview([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> checkIn([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> checkOut([Map<String, dynamic>? data]);
}
