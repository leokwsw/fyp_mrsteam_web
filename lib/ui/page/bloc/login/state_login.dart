// login_state.dart
class LoginState {
  final String username;
  final String password;
  final bool loading;
  final String? error;

  const LoginState({
    this.username = '',
    this.password = '',
    this.loading = false,
    this.error,
  });

  LoginState copyWith({
    String? username,
    String? password,
    bool? loading,
    bool? success,
    String? error,
  }) => LoginState(
    username: username ?? this.username,
    password: password ?? this.password,
    loading: loading ?? this.loading,
    error: error,
  );
}
