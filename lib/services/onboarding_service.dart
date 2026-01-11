import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _hasSeenTourKey = 'has_seen_home_tour';
  
  static Future<bool> hasSeenHomeTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenTourKey) ?? false;
  }
  
  static Future<void> setHomeTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTourKey, true);
  }
  
  static Future<void> resetHomeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenTourKey);
  }
}
