import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class AuthActions {
  final AuthRepository repository;
  AuthActions(this.repository);
  Future<Either<Failure, dynamic>> login([Map<String, dynamic>? data]) =>
      repository.login(data);
  Future<Either<Failure, dynamic>> logout([Map<String, dynamic>? data]) =>
      repository.logout(data);
}
