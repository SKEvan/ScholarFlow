import 'package:shared_preferences/shared_preferences.dart';

class BackendConfig {
  BackendConfig._();

  static const String _prefsKey = 'backend_base_url';
  static const String defaultBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://scholarflow-i4bq.onrender.com',
  );

  static String _baseUrl = defaultBaseUrl;
  static bool _loaded = false;
  static bool _hasStoredValue = false;

  static String get baseUrl => _baseUrl;

  static bool get hasCustomBaseUrl => _hasStoredValue;

  static bool _isLocalDevelopmentUrl(String value) {
    final host = Uri.tryParse(value)?.host ?? '';
    return host == '127.0.0.1' || host == 'localhost' || host == '10.0.2.2';
  }

  static Future<void> load() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _hasStoredValue = prefs.containsKey(_prefsKey);
    final storedValue = prefs.getString(_prefsKey);
    if (storedValue != null && storedValue.isNotEmpty && !_isLocalDevelopmentUrl(storedValue)) {
      _baseUrl = storedValue;
    } else {
      _baseUrl = defaultBaseUrl;
      if (storedValue != null && _isLocalDevelopmentUrl(storedValue)) {
        _hasStoredValue = false;
        await prefs.remove(_prefsKey);
      }
    }
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
