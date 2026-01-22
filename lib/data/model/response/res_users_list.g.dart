// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_users_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsersListRes _$UsersListResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UsersListRes', json, ($checkedConvert) {
      final val = UsersListRes(
        $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => UserResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        $checkedConvert('total', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$UsersListResToJson(UsersListRes instance) =>
    <String, dynamic>{'items': instance.items, 'total': instance.total};
