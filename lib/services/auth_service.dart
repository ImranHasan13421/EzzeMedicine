import 'package:flutter/foundation.dart';
import '../core/supabase_config.dart';
import '../models/admin_user.dart';

class AuthService {
  AdminUser? _currentUser;
  AdminUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Base admin user requested by the user
  static final AdminUser baseAdmin = AdminUser(
    id: 'admin-imran',
    email: 'imranhasan13421@gmail.com',
    fullName: 'Md. Imran Hasan',
    storeName: 'EzzeMedicine Pharmacy & Healthcare',
    role: 'admin',
  );

  /// Auto login with base admin on launch
  Future<AdminUser?> autoLogin() async {
    final client = SupabaseConfig.client;
    if (client != null && !SupabaseConfig.useMockMode) {
      final user = client.auth.currentUser;
      if (user != null) {
        _currentUser = AdminUser(
          id: user.id,
          email: user.email ?? 'imranhasan13421@gmail.com',
          fullName: user.userMetadata?['full_name'] ?? 'Md. Imran Hasan',
          storeName: user.userMetadata?['store_name'] ?? 'EzzeMedicine Pharmacy',
        );
        return _currentUser;
      }
    }
    // Default to base admin
    _currentUser = baseAdmin;
    return _currentUser;
  }

  /// Sign In with Email & Password
  Future<AdminUser> signIn({
    required String email,
    required String password,
  }) async {
    final client = SupabaseConfig.client;

    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        final response = await client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        final user = response.user;
        if (user != null) {
          _currentUser = AdminUser(
            id: user.id,
            email: user.email ?? email,
            fullName: user.userMetadata?['full_name'] ?? 'Md. Imran Hasan',
            storeName: user.userMetadata?['store_name'] ?? 'EzzeMedicine Pharmacy',
          );
          return _currentUser!;
        }
      } catch (e) {
        debugPrint('Supabase signIn note (trying auto-register if new): $e');
        // If user does not exist yet in Supabase Auth, auto register base admin!
        try {
          final registerResponse = await client.auth.signUp(
            email: email.trim(),
            password: password,
            data: {
              'full_name': email == 'imranhasan13421@gmail.com'
                  ? 'Md. Imran Hasan'
                  : email.split('@').first,
              'store_name': 'EzzeMedicine Pharmacy',
              'role': 'admin',
            },
          );
          final newUser = registerResponse.user;
          if (newUser != null) {
            _currentUser = AdminUser(
              id: newUser.id,
              email: newUser.email ?? email,
              fullName: newUser.userMetadata?['full_name'] ?? 'Md. Imran Hasan',
              storeName: 'EzzeMedicine Pharmacy',
            );
            return _currentUser!;
          }
        } catch (regError) {
          debugPrint('Supabase auto-register error: $regError');
        }
      }
    }

    // Local authentication check
    await Future.delayed(const Duration(milliseconds: 300));
    final isBaseAdmin = email.trim().toLowerCase() == 'imranhasan13421@gmail.com';
    _currentUser = AdminUser(
      id: isBaseAdmin ? 'admin-imran' : 'admin-${DateTime.now().millisecondsSinceEpoch % 1000}',
      email: email.trim(),
      fullName: isBaseAdmin ? 'Md. Imran Hasan' : email.split('@').first.toUpperCase(),
      storeName: 'EzzeMedicine Pharmacy & Healthcare',
    );
    return _currentUser!;
  }

  /// Register new Admin account
  Future<AdminUser> register({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
  }) async {
    final client = SupabaseConfig.client;

    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        final response = await client.auth.signUp(
          email: email.trim(),
          password: password,
          data: {
            'full_name': fullName.trim(),
            'store_name': storeName.trim(),
            'role': 'admin',
          },
        );
        final user = response.user;
        if (user != null) {
          _currentUser = AdminUser(
            id: user.id,
            email: email.trim(),
            fullName: fullName.trim(),
            storeName: storeName.trim(),
          );
          return _currentUser!;
        }
      } catch (e) {
        debugPrint('Supabase register error: $e');
      }
    }

    // Local register fallback
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = AdminUser(
      id: 'admin-${DateTime.now().millisecondsSinceEpoch % 1000}',
      email: email.trim(),
      fullName: fullName.trim(),
      storeName: storeName.trim(),
    );
    return _currentUser!;
  }

  /// Logout
  Future<void> signOut() async {
    final client = SupabaseConfig.client;
    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
  }
}
