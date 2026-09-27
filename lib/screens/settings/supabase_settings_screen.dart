import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/sql_schema.dart';
import '../../core/supabase_config.dart';
import '../../providers/auth_provider.dart';

class SupabaseSettingsScreen extends StatefulWidget {
  const SupabaseSettingsScreen({super.key});

  @override
  State<SupabaseSettingsScreen> createState() => _SupabaseSettingsScreenState();
}

class _SupabaseSettingsScreenState extends State<SupabaseSettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _anonKeyController;
  bool _useMockMode = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: SupabaseConfig.supabaseUrl);
    _anonKeyController = TextEditingController(text: SupabaseConfig.supabaseAnonKey);
    _useMockMode = SupabaseConfig.useMockMode;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  void _saveConfig() async {
    setState(() => _isSaving = true);

    final success = await SupabaseConfig.saveConfig(
      url: _urlController.text,
      anonKey: _anonKeyController.text,
      mockMode: _useMockMode,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (_useMockMode
                    ? 'Saved in Local Mock Mode'
                    : 'Supabase configuration saved & connected!')
                : 'Could not connect to Supabase. Check URL & Key.',
          ),
          backgroundColor: success ? AppColors.confirmed : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'System Settings & Supabase Integration',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect to your Supabase PostgreSQL database or run in standalone local mode',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Active Admin Profile Info
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.fullName ?? 'Admin User',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (user?.role ?? 'admin').toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'admin@ezzemedicine.com',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                          Text(
                            user?.storeName ?? AppConstants.storeName,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => authProvider.signOut(),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Supabase Mode Switcher Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _useMockMode ? AppColors.primary : Colors.blue.shade400,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _useMockMode ? Icons.desktop_windows_rounded : Icons.cloud_done_rounded,
                          color: _useMockMode ? AppColors.primary : Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _useMockMode
                                    ? 'Running in Local Standalone Mode (Active)'
                                    : 'Connected to Supabase Cloud Database',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              Text(
                                _useMockMode
                                    ? 'All medicines and orders are stored in memory and local storage. No server needed to test.'
                                    : 'All medicines, images, and customer orders synchronize with Supabase PostgreSQL.',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: !_useMockMode,
                          activeThumbColor: Colors.blue,
                          onChanged: (val) {
                            setState(() => _useMockMode = !val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Supabase Credential Inputs
                    Text(
                      'SUPABASE PROJECT CREDENTIALS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Supabase Project URL',
                        hintText: 'https://xxxxxxxx.supabase.co',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _anonKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Supabase Anon (Public) Key',
                        hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                        prefixIcon: Icon(Icons.key_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveConfig,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_isSaving ? 'Connecting...' : 'Save Configuration'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Supabase SQL Schema Generator Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.terminal_rounded, color: AppColors.secondary, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Supabase SQL Setup Script',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              Text(
                                'Run this in Supabase SQL Editor to automatically create tables, RLS policies & storage',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: SupabaseSqlSchema.fullSqlScript));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Complete Supabase SQL script copied to clipboard!'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy SQL Script'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 220,
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          SupabaseSqlSchema.fullSqlScript,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Rollback Script Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, color: Colors.redAccent, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rollback SQL Script (Safe Undo)',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.redAccent),
                              ),
                              Text(
                                'Run in Supabase SQL editor if you ever want to safely drop EzzeMedicine tables',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: SupabaseSqlSchema.rollbackSqlScript));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Rollback SQL script copied to clipboard!'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.redAccent),
                          label: const Text('Copy Rollback SQL', style: TextStyle(color: Colors.redAccent)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 100,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const SingleChildScrollView(
                        child: Text(
                          SupabaseSqlSchema.rollbackSqlScript,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFFFCA5A5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
