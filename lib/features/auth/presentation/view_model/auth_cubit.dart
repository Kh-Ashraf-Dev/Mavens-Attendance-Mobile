import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/auth_actions.dart';
import '../../../../core/widgets/load_state.dart';

class AuthCubit extends Cubit<LoadState> {
  final AuthActions actions;
  AuthCubit(this.actions) : super(const LoadState());
  Future<void> login([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.login(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }

  Future<void> logout([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.logout(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }
}
