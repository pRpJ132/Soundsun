import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';

class UserPreferences {
  static const _historyUser = "history_user_key";
  static const _playlistsKey = "playlists_key";

  static Future<List<String>?> getHistoryUser() async =>
      (await SharedPreferences.getInstance()).getStringList(_historyUser);
      
  static Future<void> setHistoryUser(List<String> history) async {
      (await SharedPreferences.getInstance()).setStringList(_historyUser, history);
  }

  static Future<Map<String, List<TrackSearchResult>>?> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_playlistsKey);

    if (data == null) return null;

    final decoded = jsonDecode(data) as Map<String, dynamic>;

    return decoded.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map((item) => TrackSearchResult.fromJson(item as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  static Future<void> setPlaylists(Map<String, List<TrackSearchResult>> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(playlists);

    await prefs.setString(_playlistsKey, encoded);
  }
}