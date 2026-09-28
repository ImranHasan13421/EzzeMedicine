import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'order_details_sheet.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  final List<OrderStatus?> _statusTabs = [
    null, // All
    OrderStatus.pendingCall,
    OrderStatus.confirmed,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<OrderProvider>().setStatusFilter(_statusTabs[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.filteredOrders;
    final pendingCount = orderProvider.pendingCallsCount;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orders & Call Verification',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Call customers from online orders, modify medicines on request, and dispatch email bills',
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Refresh Button
                FilledButton.tonalIcon(
                  onPressed: () => context.read<OrderProvider>().refreshOrders(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh Orders'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab bar for Statuses
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black87,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  const Tab(text: 'All Orders'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📞 Pending Call'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: '✅ Confirmed'),
                  const Tab(text: '🚚 Delivered'),
                  const Tab(text: '❌ Cancelled'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search orders by Order ID (e.g. EZM-1024), Customer Name, Phone, Email...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          orderProvider.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => orderProvider.setSearchQuery(val),
            ),
            const SizedBox(height: 16),

            // Orders list with Pull-to-Refresh
            Expanded(
              child: orderProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No orders matching criteria', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(
                                'Customer orders placed online will appear here automatically in real time.',
                                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () => orderProvider.refreshOrders(),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Refresh from Database'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => orderProvider.refreshOrders(),
                          child: ListView.separated(
                            itemCount: orders.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _buildOrderCard(order, isDark);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, bool isDark) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final isPending = order.status == OrderStatus.pendingCall;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isPending
              ? Colors.orange.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Order ID, Timestamp, Status Badge
            Row(
              children: [
                Text(
                  order.id,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '•  ${dateFormat.format(order.createdAt)}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                ),
                const Spacer(),
                _statusChip(order.status),
              ],
            ),
            const SizedBox(height: 10),

            // Customer details and Home Delivery status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(width: 12),
                          const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(order.customerPhone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            order.isHomeDelivery ? Icons.home_rounded : Icons.store_mall_directory_rounded,
                            size: 15,
                            color: order.isHomeDelivery ? Colors.deepOrange : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.isHomeDelivery
                                  ? 'Home Delivery: ${order.deliveryAddress ?? "Address noted"}'
                                  : 'Store Pickup',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: order.isHomeDelivery ? Colors.deepOrange : null,
                                fontWeight: order.isHomeDelivery ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Call verification indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.callStatus == CallStatus.calledConfirmed
                        ? AppColors.confirmedBg
                        : (order.callStatus == CallStatus.notCalled ? AppColors.pendingBg : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.callStatus.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: order.callStatus == CallStatus.calledConfirmed
                          ? AppColors.confirmed
                          : (order.callStatus == CallStatus.notCalled ? AppColors.pending : Colors.blue.shade800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Items breakdown summary
            Text(
              order.items.map((i) => '${i.medicineName} (${i.quantity}x)').join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700),
            ),
            const SizedBox(height: 12),

            // Bottom action row: Price & Buttons
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Bill:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      '৳${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                    ),
                  ],
                ),
                if (order.isHomeDelivery && order.deliveryCharge > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(+৳${order.deliveryCharge.toStringAsFixed(0)} delivery)',
                    style: const TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                  ),
                ],
                const Spacer(),

                // Call Customer Button
                OutlinedButton.icon(
                  onPressed: () async {
                    final orderProvider = context.read<OrderProvider>();
                    final launched = await orderProvider.triggerCustomerCall(order);
                    if (!launched && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Phone ${order.customerPhone} copied to clipboard!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.phone_forwarded_rounded, size: 16, color: AppColors.confirmed),
                  label: const Text('Call', style: TextStyle(color: AppColors.confirmed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.confirmed),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),

                // Review / Open Details Button
                ElevatedButton.icon(
                  onPressed: () => OrderDetailsSheet.show(context, order.id),
                  icon: Icon(isPending ? Icons.check_circle_outline_rounded : Icons.visibility_outlined, size: 16),
                  label: Text(isPending ? 'Review & Confirm' : 'View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending ? AppColors.primary : (isDark ? AppColors.darkCard : const Color(0xFFE2E8F0)),
                    foregroundColor: isPending ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(OrderStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case OrderStatus.pendingCall:
        bg = AppColors.pendingBg;
        fg = AppColors.pending;
        break;
      case OrderStatus.confirmed:
        bg = AppColors.confirmedBg;
        fg = AppColors.confirmed;
        break;
      case OrderStatus.cancelled:
        bg = AppColors.cancelledBg;
        fg = AppColors.cancelled;
        break;
      case OrderStatus.delivered:
        bg = AppColors.deliveredBg;
        fg = AppColors.delivered;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
