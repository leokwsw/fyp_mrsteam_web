import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _kAccessToken = "accessToken";
  static const _kRefreshToken = "refresh_token";
  static const _kSessionId = "session_id";
  static const _kUserId = "user_id";

  static late SharedPreferences _preferences;

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future<bool> setAccessToken(String value) async =>
      await _preferences.setString(_kAccessToken, value);

  static String getAccessToken() => _preferences.getString(_kAccessToken) ?? "";

  static Future<bool> setRefreshToken(String value) async =>
      await _preferences.setString(_kRefreshToken, value);

  static String getRefreshToken() =>
      _preferences.getString(_kRefreshToken) ?? "";

  static Future<bool> setSessionId(String value) async =>
      await _preferences.setString(_kSessionId, value);

  static String getSessionId() => _preferences.getString(_kSessionId) ?? "";

  static Future<bool> setUserId(String value) async =>
      await _preferences.setString(_kUserId, value);

  static String getUserId() => _preferences.getString(_kUserId) ?? "";

  static Future<bool> clear() async => _preferences.clear();
}
