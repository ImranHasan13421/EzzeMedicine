import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'medicines/medicine_list_screen.dart';
import 'orders/order_list_screen.dart';
import 'profile/profile_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const MainLayoutScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final orderProvider = context.watch<OrderProvider>();
    final authProvider = context.watch<AuthProvider>();
    final pendingCount = orderProvider.pendingCallsCount;
    final user = authProvider.user;

    final screens = [
      DashboardScreen(onNavigate: _navigateTo),
      const MedicineListScreen(),
      const OrderListScreen(),
      const ProfileScreen(),
    ];

    if (isDesktop) {
      // Desktop / Tablet Layout with Left Sidebar
      return Scaffold(
        body: Row(
          children: [
            // Left Navigation Sidebar
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  right: BorderSide(
                    color: widget.isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // App Brand Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EzzeMedicine',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                'Admin Operations',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.isDark ? Colors.white60 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Navigation Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _sidebarItem(
                          index: 0,
                          title: 'Dashboard',
                          icon: Icons.dashboard_rounded,
                        ),
                        _sidebarItem(
                          index: 1,
                          title: 'Medicine Inventory',
                          icon: Icons.medication_rounded,
                        ),
                        _sidebarItem(
                          index: 2,
                          title: 'Orders & Calls',
                          icon: Icons.receipt_long_rounded,
                          badgeCount: pendingCount,
                        ),
                        _sidebarItem(
                          index: 3,
                          title: 'Admin Profile',
                          icon: Icons.person_rounded,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),
                  // User Profile & Theme switcher footer
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'Admin',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    'Pharmacist Admin',
                                    style: TextStyle(fontSize: 11, color: widget.isDark ? Colors.white60 : Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                size: 20,
                              ),
                              tooltip: 'Toggle Theme',
                              onPressed: widget.onToggleTheme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile / Android Layout
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _currentIndex == 0
                ? 'Dashboard'
                : _currentIndex == 1
                    ? 'Inventory'
                    : _currentIndex == 2
                        ? 'Orders & Calls'
                        : 'Admin Profile',
          ),
          actions: [
            IconButton(
              icon: Icon(
                widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _navigateTo,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.medication_outlined),
              selectedIcon: Icon(Icons.medication_rounded),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text('$pendingCount'),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text('$pendingCount'),
                child: const Icon(Icons.receipt_long_rounded),
              ),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      );
    }
  }

  Widget _sidebarItem({
    required int index,
    required String title,
    required IconData icon,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _navigateTo(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : (widget.isDark ? Colors.white70 : Colors.grey.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isSelected ? AppColors.primary : (widget.isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
