class HomeState {
  final bool loading;
  final String? error;

  const HomeState({this.loading = false, this.error});

  HomeState copyWith({bool? loading, String? error}) =>
      HomeState(loading: loading ?? this.loading, error: error);
}
