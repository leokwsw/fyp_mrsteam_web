import 'package:json_annotation/json_annotation.dart';

part 'res_user.g.dart';

@JsonSerializable()
class UserResponse {
  @JsonKey(name: '_id')
  final String? id;
  final String? username;
  final String email;
  final String name;
  final String? role;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  UserResponse(
    this.email,
    this.name, {
    this.id,
    this.username,
    this.role,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserResponseToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      UserResponse.fromJson(json);
}
