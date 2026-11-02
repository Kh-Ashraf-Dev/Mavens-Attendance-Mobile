class LoadState {
  final bool busy;
  final dynamic data;
  final String? error;
  final int? status;
  const LoadState({this.busy = false, this.data, this.error, this.status});
}
