import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/attendance_actions.dart';
import '../../../../core/widgets/load_state.dart';

class AttendanceCubit extends Cubit<LoadState> {
  final AttendanceActions actions;
  AttendanceCubit(this.actions) : super(const LoadState());
  Future<void> overview([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.overview(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }

  Future<void> checkIn([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.checkIn(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }

  Future<void> checkOut([Map<String, dynamic>? data]) async {
    emit(const LoadState(busy: true));
    final result = await actions.checkOut(data);
    if (isClosed) return;
    result.fold(
      (f) => emit(LoadState(error: f.message, status: f.status)),
      (v) => emit(LoadState(data: v)),
    );
  }
}
