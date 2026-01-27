// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_users_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsersListRes _$UsersListResFromJson(Map<String, dynamic> json) => UsersListRes(
  (json['items'] as List<dynamic>)
      .map((e) => UserResponse.fromJson(e as Map<String, dynamic>))
      .toList(),
  (json['total'] as num).toInt(),
);

Map<String, dynamic> _$UsersListResToJson(UsersListRes instance) =>
    <String, dynamic>{'items': instance.items, 'total': instance.total};
