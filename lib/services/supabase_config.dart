import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A class to handle Supabase configuration and credentials
class SupabaseConfig {
  static const _secureStorage = FlutterSecureStorage();

  // Keys for secure storage
  static const String _supabaseUrlKey = 'supabase_url';
  static const String _supabaseAnonKeyKey = 'supabase_anon_key';

  /// Store Supabase URL in secure storage
  static Future<void> storeSupabaseUrl(String url) async {
    await _secureStorage.write(key: _supabaseUrlKey, value: url);
  }

  /// Store Supabase anon key in secure storage
  static Future<void> storeSupabaseAnonKey(String key) async {
    await _secureStorage.write(key: _supabaseAnonKeyKey, value: key);
  }

  /// Get Supabase URL from secure storage
  static Future<String?> getSupabaseUrl() async {
    return await _secureStorage.read(key: _supabaseUrlKey);
  }

  /// Get Supabase anon key from secure storage
  static Future<String?> getSupabaseAnonKey() async {
    return await _secureStorage.read(key: _supabaseAnonKeyKey);
  }

  /// Check if Supabase is configured
  static Future<bool> isConfigured() async {
    final url = await getSupabaseUrl();
    final key = await getSupabaseAnonKey();
    return url != null && key != null;
  }

  /// Initialize Supabase configuration with default values if not set
  static Future<void> initializeIfNeeded(
      String defaultUrl, String defaultKey) async {
    if (!await isConfigured()) {
      await storeSupabaseUrl(defaultUrl);
      await storeSupabaseAnonKey(defaultKey);
    }
  }
}
