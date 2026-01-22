// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UserResponse', json, ($checkedConvert) {
      final val = UserResponse(
        $checkedConvert('email', (v) => v as String),
        $checkedConvert('name', (v) => v as String),
        id: $checkedConvert('_id', (v) => v as String?),
        username: $checkedConvert('username', (v) => v as String?),
        role: $checkedConvert('role', (v) => v as String?),
        isActive: $checkedConvert('isActive', (v) => v as bool?),
        createdAt: $checkedConvert('createdAt', (v) => v as String?),
        updatedAt: $checkedConvert('updatedAt', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'id': '_id'});

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
