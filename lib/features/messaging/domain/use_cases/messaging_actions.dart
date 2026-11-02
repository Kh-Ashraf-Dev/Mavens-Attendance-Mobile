import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/messaging_repository.dart';

class MessagingActions {
  final MessagingRepository repository;
  MessagingActions(this.repository);
  Future<Either<Failure, dynamic>> list([Map<String, dynamic>? data]) =>
      repository.list(data);
  Future<Either<Failure, dynamic>> send([Map<String, dynamic>? data]) =>
      repository.send(data);
  Future<Either<Failure, dynamic>> directory([Map<String, dynamic>? data]) =>
      repository.directory(data);
  Future<Either<Failure, dynamic>> markRead([Map<String, dynamic>? data]) =>
      repository.markRead(data);
}
