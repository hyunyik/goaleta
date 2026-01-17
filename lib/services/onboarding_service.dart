import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _hasSeenTourKey = 'has_seen_home_tour';
  static const String _hasSeenGoalFormTourKey = 'has_seen_goal_form_tour';
  static const String _hasSeenLogFormTourKey = 'has_seen_log_form_tour';
  
  // Home Tour
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
  
  // Goal Form Tour
  static Future<bool> hasSeenGoalFormTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenGoalFormTourKey) ?? false;
  }
  
  static Future<void> setGoalFormTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenGoalFormTourKey, true);
  }
  
  static Future<void> resetGoalFormTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenGoalFormTourKey);
  }
  
  // Log Form Tour
  static Future<bool> hasSeenLogFormTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenLogFormTourKey) ?? false;
  }
  
  static Future<void> setLogFormTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenLogFormTourKey, true);
  }
  
  static Future<void> resetLogFormTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenLogFormTourKey);
  }
}
