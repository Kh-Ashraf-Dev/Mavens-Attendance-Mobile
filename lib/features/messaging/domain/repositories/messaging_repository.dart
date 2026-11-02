import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';

abstract class MessagingRepository {
  Future<Either<Failure, dynamic>> list([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> send([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> directory([Map<String, dynamic>? data]);
  Future<Either<Failure, dynamic>> markRead([Map<String, dynamic>? data]);
}
