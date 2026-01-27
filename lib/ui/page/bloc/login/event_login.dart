// login_event.dart
sealed class LoginEvent {}
class UsernameChanged extends LoginEvent {
  final String username;
  UsernameChanged(this.username);
}
class PasswordChanged extends LoginEvent {
  final String password;
  PasswordChanged(this.password);
}
class LoginSubmitted extends LoginEvent {}
