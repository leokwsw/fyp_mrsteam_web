// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
  json['email'] as String,
  json['name'] as String,
  id: json['_id'] as String?,
  username: json['username'] as String?,
  role: json['role'] as String?,
  isActive: json['isActive'] as bool?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'name': instance.name,
      'role': instance.role,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
