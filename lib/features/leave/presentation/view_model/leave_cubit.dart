import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/leave_actions.dart';
import '../../../../core/widgets/load_state.dart';

class LeaveCubit extends Cubit<LoadState> {
  final LeaveActions actions;
  LeaveCubit(this.actions) : super(const LoadState());
  Future<void> list([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.list(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }

  Future<void> request([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.request(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }

  Future<void> inbox([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.inbox(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }
}
