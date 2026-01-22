import 'package:json_annotation/json_annotation.dart';

part 'res_signed_url.g.dart';

@JsonSerializable()
class SignedUrlRes {
  final String url;
  final num? expiresIn;

  SignedUrlRes(this.url, {this.expiresIn});

  factory SignedUrlRes.fromJson(Map<String, dynamic> json) =>
      _$SignedUrlResFromJson(json);

  Map<String, dynamic> toJson() => _$SignedUrlResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      SignedUrlRes.fromJson(json);
}
