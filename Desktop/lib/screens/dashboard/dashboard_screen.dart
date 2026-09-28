import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/order_model.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/order_provider.dart';
import '../medicines/medicine_form_dialog.dart';
import '../orders/order_details_sheet.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderProvider = context.watch<OrderProvider>();
    final medProvider = context.watch<MedicineProvider>();

    final pendingOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.pendingCall)
        .take(4)
        .toList();

    final lowStockMeds = medProvider.medicines
        .where((m) => m.isLowStock || m.isOutOfStock)
        .take(4)
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<OrderProvider>().refreshOrders(),
            context.read<MedicineProvider>().refreshMedicines(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Welcome
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pharmacy Operations Dashboard',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Live orders, customer verification calls, and pharmacy inventory control',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      context.read<OrderProvider>().refreshOrders();
                      context.read<MedicineProvider>().refreshMedicines();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => MedicineFormDialog.show(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Medicine'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

            // Top KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1000
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
                  children: [
                    _kpiCard(
                      title: 'TOTAL REVENUE',
                      value: '৳${orderProvider.totalRevenue.toStringAsFixed(2)}',
                      subtitle: 'Confirmed & Delivered',
                      icon: Icons.payments_rounded,
                      color: AppColors.primary,
                      isDark: isDark,
                      onTap: () => onNavigate(2),
                    ),
                    _kpiCard(
                      title: 'PENDING CALLS',
                      value: '${orderProvider.pendingCallsCount}',
                      subtitle: 'Awaiting customer verification',
                      icon: Icons.phone_in_talk_rounded,
                      color: AppColors.pending,
                      alert: orderProvider.pendingCallsCount > 0,
                      isDark: isDark,
                      onTap: () => onNavigate(2),
                    ),
                    _kpiCard(
                      title: 'CATALOG MEDICINES',
                      value: '${medProvider.totalCount}',
                      subtitle: 'Active inventory items',
                      icon: Icons.medication_rounded,
                      color: AppColors.secondary,
                      isDark: isDark,
                      onTap: () => onNavigate(1),
                    ),
                    _kpiCard(
                      title: 'LOW STOCK ALERTS',
                      value: '${medProvider.lowStockCount + medProvider.outOfStockCount}',
                      subtitle: 'Needs replenishment',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.lowStock,
                      alert: (medProvider.lowStockCount + medProvider.outOfStockCount) > 0,
                      isDark: isDark,
                      onTap: () => onNavigate(1),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Section: Urgent Action Needed (Pending Calls)
            Row(
              children: [
                const Icon(Icons.phone_callback_rounded, color: AppColors.pending, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'URGENT: PENDING CUSTOMER CALLS (${orderProvider.pendingCallsCount})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigate(2),
                  child: const Text('View All Orders →'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (pendingOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.confirmed),
                      const SizedBox(height: 8),
                      const Text('All orders have been called and verified!', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'New customer requests from the public store will show up here automatically.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingOrders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = pendingOrders[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.pendingBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.pending, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(order.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Text('• ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(width: 8),
                                  if (order.isHomeDelivery)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Home Delivery', style: TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phone: ${order.customerPhone} • Items: ${order.items.map((i) => i.medicineName).join(', ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        // Quick Call
                        OutlinedButton.icon(
                          onPressed: () => context.read<OrderProvider>().triggerCustomerCall(order),
                          icon: const Icon(Icons.phone_forwarded_rounded, size: 16, color: AppColors.confirmed),
                          label: const Text('Call', style: TextStyle(color: AppColors.confirmed)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.confirmed)),
                        ),
                        const SizedBox(width: 10),
                        // Review & Confirm
                        ElevatedButton(
                          onPressed: () => OrderDetailsSheet.show(context, order.id),
                          child: const Text('Verify & Confirm'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 28),

            // Section: Inventory Alerts & Fast Stock Control
            Row(
              children: [
                const Icon(Icons.inventory_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'STOCK HEALTH & REPLENISHMENT ALERTS',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigate(1),
                  child: const Text('View All Medicines →'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (lowStockMeds.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text('All medicines have healthy stock levels.', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lowStockMeds.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final med = lowStockMeds[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: med.isOutOfStock ? Colors.red.shade300 : Colors.deepOrange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          med.isOutOfStock ? Icons.cancel_outlined : Icons.warning_amber_rounded,
                          color: med.isOutOfStock ? Colors.red : Colors.deepOrange,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(med.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(
                                '${med.category} • ${med.strength} • Current Stock: ${med.stockQuantity} (Alert at ${med.minStockAlert})',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        // Quick restock +20 button
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<MedicineProvider>().adjustStock(med.id, 20);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added 20 units to "${med.name}" stock!')),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                          label: const Text('Restock +20'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool alert = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: alert ? color : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            width: alert ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: alert ? color : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
