import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of the admin portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Material(
      color: Colors.transparent,
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<AuthProvider>().reloadProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Title
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator Profile & About',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pharmacy administrator information and system operations summary',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        context.read<AuthProvider>().reloadProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile & database status refreshed'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

              // Admin Profile Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'M').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.fullName ?? 'Md. Imran Hasan',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'LEAD PHARMACIST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 15, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                user?.email ?? 'imranhasan13421@gmail.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined, size: 15, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                user?.storeName ?? AppConstants.storeName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Database & Connection Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_done_rounded, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Supabase Database Connected',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Project: Ezze Softwares • Tables: EzzeMedicine_medicines & EzzeMedicine_orders',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Readme & Workflow Overview Box
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'HOW EZZEMEDICINE WORKS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _workflowStep(
                      step: '1',
                      title: 'Public Online Medicine Catalog',
                      description: 'Customers browse available medicines, search by brand/generic name, and add items to their shopping cart.',
                      isDark: isDark,
                    ),
                    _workflowStep(
                      step: '2',
                      title: 'Customer Submits Order Request',
                      description: 'Customer inputs their Name, Phone number, Email, and chooses Store Pickup or Home Delivery (with address). No password is required.',
                      isDark: isDark,
                    ),
                    _workflowStep(
                      step: '3',
                      title: 'Admin Verification Phone Call (Offline Action)',
                      description: 'The order immediately arrives in the Admin App. The pharmacist calls the customer to verify medicines, dosage, and delivery details.',
                      isDark: isDark,
                    ),
                    _workflowStep(
                      step: '4',
                      title: 'Live Order Modifications on Call',
                      description: 'If the customer asks to add more medicines or modify quantities during the call, the pharmacist edits items directly from the catalog.',
                      isDark: isDark,
                    ),
                    _workflowStep(
                      step: '5',
                      title: 'Manual Home Delivery Charge',
                      description: 'If Home Delivery is chosen, the admin sets the delivery fee agreed upon with the customer during confirmation.',
                      isDark: isDark,
                    ),
                    _workflowStep(
                      step: '6',
                      title: 'Confirmation & Automated Email Bill',
                      description: 'Pharmacist confirms the order in the app. An official itemized invoice bill is dispatched to the customer\'s email.',
                      isDark: isDark,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Sign Out Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context),
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text('Sign Out from Admin Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'EzzeMedicine Pharmacy System • Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _workflowStep({
    required String step,
    required String title,
    required String description,
    required bool isDark,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
