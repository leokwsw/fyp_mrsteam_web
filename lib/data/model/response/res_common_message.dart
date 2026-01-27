import 'package:json_annotation/json_annotation.dart';

part 'res_common_message.g.dart';

@JsonSerializable()
class CommonMessage {
  final String message;

  CommonMessage(this.message);

  factory CommonMessage.fromJson(Map<String, dynamic> json) =>
      _$CommonMessageFromJson(json);

  Map<String, dynamic> toJson() => _$CommonMessageToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CommonMessage.fromJson(json);
}
