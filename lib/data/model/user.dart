import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String username;
  final String name;

  User(
    this.id,
    this.username,
    this.name,
  );

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => User.fromJson(json);
}