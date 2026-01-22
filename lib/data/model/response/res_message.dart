import 'package:json_annotation/json_annotation.dart';

part 'res_message.g.dart';

@JsonSerializable()
class MessageRes {
  final bool success;
  final String message;

  MessageRes(this.success, this.message);

  factory MessageRes.fromJson(Map<String, dynamic> json) =>
      _$MessageResFromJson(json);

  Map<String, dynamic> toJson() => _$MessageResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => MessageRes.fromJson(json);
}
