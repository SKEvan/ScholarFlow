import 'package:shared_preferences/shared_preferences.dart';

class BackendConfig {
  BackendConfig._();

  static const String _prefsKey = 'backend_base_url';
  static const String defaultBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static String _baseUrl = defaultBaseUrl;
  static bool _loaded = false;
  static bool _hasStoredValue = false;

  static String get baseUrl => _baseUrl;

  static bool get hasCustomBaseUrl => _hasStoredValue;

  static Future<void> load() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _hasStoredValue = prefs.containsKey(_prefsKey);
    _baseUrl = prefs.getString(_prefsKey) ?? defaultBaseUrl;
    _loaded = true;
  }

  static Future<void> setBaseUrl(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = normalized;
    _hasStoredValue = true;
    _loaded = true;
    await prefs.setString(_prefsKey, normalized);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = defaultBaseUrl;
    _hasStoredValue = false;
    _loaded = true;
    await prefs.remove(_prefsKey);
  }
}
