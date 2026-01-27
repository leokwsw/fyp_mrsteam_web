// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_signed_url.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignedUrlRes _$SignedUrlResFromJson(Map<String, dynamic> json) =>
    SignedUrlRes(json['url'] as String, expiresIn: json['expiresIn'] as num?);

Map<String, dynamic> _$SignedUrlResToJson(SignedUrlRes instance) =>
    <String, dynamic>{'url': instance.url, 'expiresIn': instance.expiresIn};
