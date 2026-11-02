import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/messaging_actions.dart';
import '../../../../core/widgets/load_state.dart';

class MessagingCubit extends Cubit<LoadState> {
  final MessagingActions actions;
  MessagingCubit(this.actions) : super(const LoadState());
  Future<void> list([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.list(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }

  Future<void> send([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.send(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }

  Future<void> directory([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.directory(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }
}
