import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/team_actions.dart';
import '../../../../core/widgets/load_state.dart';

class TeamCubit extends Cubit<LoadState> {
  final TeamActions actions;
  TeamCubit(this.actions) : super(const LoadState());
  Future<void> load([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.load(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }
}
