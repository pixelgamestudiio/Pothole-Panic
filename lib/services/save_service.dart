import 'package:shared_preferences/shared_preferences.dart';

class SaveService {
  SaveService(this.prefs);
  final SharedPreferences prefs;
  int get best => prefs.getInt('best') ?? 0;
  int get runs => prefs.getInt('runs') ?? 0;
  int get totalFare => prefs.getInt('totalFare') ?? 0;
  bool get sound => prefs.getBool('sound') ?? true;
  Future<void> setSound(bool value) => prefs.setBool('sound', value);
  Future<void> saveBest(int score) async {
    if (score > best) await prefs.setInt('best', score);
  }

  Future<void> record(int score, int fare) async {
    await saveBest(score);
    await prefs.setInt('runs', runs + 1);
    await prefs.setInt('totalFare', totalFare + fare);
  }
}
