import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'core/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/order_provider.dart';
import 'screens/auth/login_register_screen.dart';
import 'screens/main_layout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load any saved Supabase configurations or defaults
  await SupabaseConfig.loadConfig();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const EzzeMedicineAdminApp(),
    ),
  );
}

class EzzeMedicineAdminApp extends StatefulWidget {
  const EzzeMedicineAdminApp({super.key});

  @override
  State<EzzeMedicineAdminApp> createState() => _EzzeMedicineAdminAppState();
}

class _EzzeMedicineAdminAppState extends State<EzzeMedicineAdminApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = _themeMode == ThemeMode.dark;

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: authProvider.isAuthenticated
          ? MainLayoutScreen(
              onToggleTheme: _toggleTheme,
              isDark: isDark,
            )
          : const LoginRegisterScreen(),
    );
  }
}
