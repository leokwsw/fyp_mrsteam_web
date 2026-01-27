class RawJsonRes {
  final Map<String, dynamic> raw;

  RawJsonRes(this.raw);

  factory RawJsonRes.fromJson(Map<String, dynamic> json) => RawJsonRes(json);

  Map<String, dynamic> toJson() => raw;

  static fromJsonModel(Map<String, dynamic> json) => RawJsonRes.fromJson(json);
}
