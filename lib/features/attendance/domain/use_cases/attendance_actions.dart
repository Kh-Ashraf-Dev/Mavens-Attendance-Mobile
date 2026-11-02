import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/attendance_repository.dart';

class AttendanceActions {
  final AttendanceRepository repository;
  AttendanceActions(this.repository);
  Future<Either<Failure, dynamic>> overview([Map<String, dynamic>? data]) =>
      repository.overview(data);
  Future<Either<Failure, dynamic>> checkIn([Map<String, dynamic>? data]) =>
      repository.checkIn(data);
  Future<Either<Failure, dynamic>> checkOut([Map<String, dynamic>? data]) =>
      repository.checkOut(data);
}
