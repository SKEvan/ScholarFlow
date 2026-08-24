import 'package:shared_preferences/shared_preferences.dart';

/// Simple app-wide store for the signed-in user's id and email.
///
/// Your sign-in flow goes through the custom backend (BackendApi.signIn),
/// not the Supabase SDK's own session, so Supabase.instance.client.auth.currentUser
/// is not reliable. Call UserSession.setUserId(...) right after a successful
/// sign-in/sign-up, and read UserSession.userId anywhere you need the owner id.
class UserSession {
  UserSession._();

  static const _prefsKey = 'current_user_id';
  static const _emailKey = 'current_user_email';
  static String? _userId;
  static String? _userEmail;

  /// Current user id, if any user is signed in and the session has been
  /// loaded (call `load()` once at app startup, e.g. in main() or splash screen).
  static String? get userId => _userId;

  /// Current user email, if known. Used by the invitations inbox to
  /// filter rows addressed to this user. Call `setEmail(...)` right after
  /// a successful sign-in/sign-up.
  static String? get userEmail => _userEmail;

  /// Loads the persisted user id + email into memory. Call this once at
  /// app startup (e.g. in main() before runApp, or in SplashScreen.initState)
  /// so UserSession.userId / UserSession.userEmail are available synchronously
  /// afterward.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_prefsKey);
    _userEmail = prefs.getString(_emailKey);
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

  /// Persist the signed-in user's email. Optional — set this from
  /// sign-in/sign-up flows if you want the invitations inbox to work
  /// without an extra profile lookup.
  static Future<void> setEmail(String? email) async {
    final normalized = (email == null || email.trim().isEmpty)
        ? null
        : email.trim();
    _userEmail = normalized;
    final prefs = await SharedPreferences.getInstance();
    if (normalized == null) {
      await prefs.remove(_emailKey);
    } else {
      await prefs.setString(_emailKey, normalized);
    }
  }

  /// Convenience: set id + email in one call.
  static Future<void> setIdentity({
    required String? userId,
    required String? email,
  }) async {
    await setUserId(userId);
    await setEmail(email);
  }

  /// Call this on sign-out.
  static Future<void> clear() async {
    _userId = null;
    _userEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_emailKey);
  }
}