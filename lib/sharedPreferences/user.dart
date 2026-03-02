import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const _historyUser = "history_user_key";

  static Future<List<String>?> getHistoryUser() async =>
      (await SharedPreferences.getInstance()).getStringList(_historyUser);
      
  static Future<void> setHistoryUser(List<String> history) async {
      (await SharedPreferences.getInstance()).setStringList(_historyUser, history);
  }
}