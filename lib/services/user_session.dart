import 'package:shared_preferences/shared_preferences.dart';

/// Simple app-wide store for the signed-in user's id.
///
/// Your sign-in flow goes through the custom backend (BackendApi.signIn),
/// not the Supabase SDK's own session, so Supabase.instance.client.auth.currentUser
/// is not reliable. Call UserSession.setUserId(...) right after a successful
/// sign-in/sign-up, and read UserSession.userId anywhere you need the owner id.
class UserSession {
  UserSession._();

  static const _prefsKey = 'current_user_id';
  static String? _userId;

  /// Current user id, if any user is signed in and the session has been
  /// loaded (call `load()` once at app startup, e.g. in main() or splash screen).
  static String? get userId => _userId;

  /// Loads the persisted user id into memory. Call this once at app startup
  /// (e.g. in main() before runApp, or in SplashScreen.initState) so
  /// UserSession.userId is available synchronously afterward.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_prefsKey);
  }

  /// Call this right after a successful sign-in or sign-up response comes
  /// back from the backend, passing result['user']['id'].
  static Future<void> setUserId(String? userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    if (userId == null || userId.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, userId);
    }
  }

  /// Call this on sign-out.
  static Future<void> clear() async {
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}