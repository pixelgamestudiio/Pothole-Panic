import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/vehicle.dart';
import '../game/friend_challenge.dart';

class SaveService {
  SaveService(this.prefs) {
    try {
      final data = jsonDecode(prefs.getString('garage_v1') ?? '{}') as Map;
      _coins = (data['coins'] as int? ?? 0).clamp(0, 1000000000);
      _unlocked.addAll((data['unlocked'] as List? ?? []).whereType<String>());
      final saved = Vehicle.fromId(data['selected'] as String?);
      _selected = isUnlocked(saved) ? saved : Vehicle.auto;
    } catch (_) {
      // Older saves have no garage. A malformed garage cannot break the game.
      _coins = 0;
      _unlocked.clear();
      _unlocked.add(Vehicle.auto.name);
      _selected = Vehicle.auto;
    }
  }
  final SharedPreferences prefs;
  int _coins = 0;
  final Set<String> _unlocked = {Vehicle.auto.name};
  Vehicle _selected = Vehicle.auto;
  Future<void> _pending = Future.value();
  int get coins => _coins;
  Vehicle get selectedVehicle => _selected;
  bool isUnlocked(Vehicle vehicle) => _unlocked.contains(vehicle.name);

  // Serialize each wallet mutation and persist balance + ownership together.
  Future<bool> _changeGarage(void Function() change) {
    final operation = _pending.then((_) async {
      final oldCoins = _coins;
      final oldSelected = _selected;
      final oldUnlocked = Set<String>.of(_unlocked);
      try {
        change();
        final saved = await prefs.setString(
          'garage_v1',
          jsonEncode({
            'coins': _coins,
            'selected': _selected.name,
            'unlocked': _unlocked.toList(),
          }),
        );
        if (!saved) throw StateError('Storage unavailable');
        return true;
      } catch (_) {
        _coins = oldCoins;
        _selected = oldSelected;
        _unlocked
          ..clear()
          ..addAll(oldUnlocked);
        return false;
      }
    });
    _pending = operation.then((_) {});
    return operation;
  }

  Future<bool> creditCoins(int amount) => _changeGarage(() {
    if (amount <= 0) throw ArgumentError.value(amount);
    _coins += amount;
  });

  Future<bool> selectOrUnlock(Vehicle vehicle) => _changeGarage(() {
    if (!isUnlocked(vehicle)) {
      if (_coins < vehicle.price) throw StateError('Not enough coins');
      _coins -= vehicle.price;
      _unlocked.add(vehicle.name);
    }
    _selected = vehicle;
  });
  int get best => prefs.getInt('best') ?? 0;
  int get runs => prefs.getInt('runs') ?? 0;
  int get totalFare => prefs.getInt('totalFare') ?? 0;
  bool get sound => prefs.getBool('sound') ?? true;
  FriendChallenge? get lastChallenge {
    try {
      return FriendChallenge.parse(
        prefs.getString('last_friend_challenge') ?? '',
      );
    } on FormatException {
      return null;
    }
  }

  Future<bool> saveChallenge(FriendChallenge value) =>
      prefs.setString('last_friend_challenge', value.code);
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
