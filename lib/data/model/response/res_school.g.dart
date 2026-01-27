// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_school.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolGpsRes _$SchoolGpsResFromJson(Map<String, dynamic> json) => SchoolGpsRes(
  (json['lat'] as num).toDouble(),
  (json['long'] as num).toDouble(),
);

Map<String, dynamic> _$SchoolGpsResToJson(SchoolGpsRes instance) =>
    <String, dynamic>{'lat': instance.lat, 'long': instance.longitude};

SchoolRes _$SchoolResFromJson(Map<String, dynamic> json) => SchoolRes(
  json['name'] as String,
  json['gps'] == null
      ? null
      : SchoolGpsRes.fromJson(json['gps'] as Map<String, dynamic>),
  id: json['_id'] as String?,
  isDeleted: json['isDeleted'] as bool?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$SchoolResToJson(SchoolRes instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'gps': instance.gps,
  'isDeleted': instance.isDeleted,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

SchoolListRes _$SchoolListResFromJson(Map<String, dynamic> json) =>
    SchoolListRes(
      (json['items'] as List<dynamic>)
          .map((e) => SchoolRes.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['total'] as num).toInt(),
      (json['page'] as num).toInt(),
      (json['limit'] as num).toInt(),
      (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$SchoolListResToJson(SchoolListRes instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'pages': instance.pages,
    };
