import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _prefUrlKey = 'ezze_supabase_url';
  static const String _prefAnonKey = 'ezze_supabase_anon_key';
  static const String _prefUseMockKey = 'ezze_use_mock_mode';

  // Configured with user's Supabase project "Ezze Softwares"
  static String supabaseUrl = 'https://xuvvxyeimdnoptqhyotn.supabase.co';
  static String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1dnZ4eWVpbWRub3B0cWh5b3RuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTkwMjIsImV4cCI6MjA5MTczNTAyMn0.F0gl-OwTWqZKEHsAvW6pAoKNxNWJeJ_JN5TbFuFtBec';
  static bool useMockMode = false; // Connect to live Supabase!

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized || useMockMode) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Load persisted configuration from SharedPreferences or initialize default
  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUrl = prefs.getString(_prefUrlKey);
      final storedKey = prefs.getString(_prefAnonKey);
      final storedMock = prefs.getBool(_prefUseMockKey);

      if (storedUrl != null && storedUrl.isNotEmpty) {
        supabaseUrl = storedUrl;
      }
      if (storedKey != null && storedKey.isNotEmpty) {
        supabaseAnonKey = storedKey;
      }
      if (storedMock != null) {
        useMockMode = storedMock;
      }

      if (!useMockMode && supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
        await initSupabase(supabaseUrl, supabaseAnonKey);
      }
    } catch (e) {
      debugPrint('Error loading Supabase config: $e');
    }
  }

  /// Save new Supabase credentials and initialize client
  static Future<bool> saveConfig({
    required String url,
    required String anonKey,
    required bool mockMode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUrlKey, url.trim());
      await prefs.setString(_prefAnonKey, anonKey.trim());
      await prefs.setBool(_prefUseMockKey, mockMode);

      supabaseUrl = url.trim();
      supabaseAnonKey = anonKey.trim();
      useMockMode = mockMode;

      if (!useMockMode && supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
        return await initSupabase(supabaseUrl, supabaseAnonKey);
      }
      return true;
    } catch (e) {
      debugPrint('Failed to save Supabase config: $e');
      return false;
    }
  }

  /// Initialize Supabase Flutter instance
  static Future<bool> initSupabase(String url, String anonKey) async {
    try {
      if (url.isEmpty || anonKey.isEmpty) return false;
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Supabase init error: $e');
      _isInitialized = false;
      return false;
    }
  }
}
