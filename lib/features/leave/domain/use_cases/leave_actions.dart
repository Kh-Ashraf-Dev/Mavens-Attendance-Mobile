import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/leave_repository.dart';

class LeaveActions {
  final LeaveRepository repository;
  LeaveActions(this.repository);
  Future<Either<Failure, dynamic>> list([Map<String, dynamic>? data]) =>
      repository.list(data);
  Future<Either<Failure, dynamic>> request([Map<String, dynamic>? data]) =>
      repository.request(data);
  Future<Either<Failure, dynamic>> inbox([Map<String, dynamic>? data]) =>
      repository.inbox(data);
  Future<Either<Failure, dynamic>> review([Map<String, dynamic>? data]) =>
      repository.review(data);
  Future<Either<Failure, dynamic>> cancel([Map<String, dynamic>? data]) =>
      repository.cancel(data);
  Future<Either<Failure, dynamic>> balance([Map<String, dynamic>? data]) =>
      repository.balance(data);
}
