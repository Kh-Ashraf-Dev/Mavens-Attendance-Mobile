import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../data_sources/attendance_remote_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteSource source;
  AttendanceRepositoryImpl(this.source);
  @override
  Future<Either<Failure, dynamic>> overview([
    Map<String, dynamic>? data,
  ]) async => await source.overview(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> checkIn([
    Map<String, dynamic>? data,
  ]) async => await source.checkIn(data) as Either<Failure, dynamic>;
  @override
  Future<Either<Failure, dynamic>> checkOut([
    Map<String, dynamic>? data,
  ]) async => await source.checkOut(data) as Either<Failure, dynamic>;
}
