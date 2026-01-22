import 'package:json_annotation/json_annotation.dart';

import 'res_user.dart';

part 'res_users_list.g.dart';

@JsonSerializable()
class UsersListRes {
  final List<UserResponse> items;
  final int total;

  UsersListRes(this.items, this.total);

  factory UsersListRes.fromJson(Map<String, dynamic> json) =>
      _$UsersListResFromJson(json);

  Map<String, dynamic> toJson() => _$UsersListResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      UsersListRes.fromJson(json);
}
