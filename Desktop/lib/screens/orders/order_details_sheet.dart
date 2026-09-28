import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../invoices/invoice_view_dialog.dart';
import 'order_edit_items_dialog.dart';

class OrderDetailsSheet extends StatefulWidget {
  final String orderId;

  const OrderDetailsSheet({super.key, required this.orderId});

  static void show(BuildContext context, String orderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderDetailsSheet(orderId: orderId),
    );
  }

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet> {
  late TextEditingController _deliveryChargeController;
  late TextEditingController _callNotesController;
  CallStatus? _selectedCallStatus;

  @override
  void initState() {
    super.initState();
    final order = context.read<OrderProvider>().getOrderById(widget.orderId);
    _deliveryChargeController = TextEditingController(
      text: order != null ? order.deliveryCharge.toStringAsFixed(0) : '0',
    );
    _callNotesController = TextEditingController(text: order?.callNotes ?? '');
    _selectedCallStatus = order?.callStatus ?? CallStatus.notCalled;
  }

  @override
  void dispose() {
    _deliveryChargeController.dispose();
    _callNotesController.dispose();
    super.dispose();
  }

  void _triggerCall(OrderModel order) async {
    final orderProvider = context.read<OrderProvider>();
    final launched = await orderProvider.triggerCustomerCall(order);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone ${order.customerPhone} copied to clipboard (Ready to dial)'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmOrder(OrderModel order) async {
    final orderProvider = context.read<OrderProvider>();
    final charge = double.tryParse(_deliveryChargeController.text) ?? order.deliveryCharge;

    final confirmed = await orderProvider.confirmOrder(
      orderId: order.id,
      manualDeliveryCharge: charge,
      notes: _callNotesController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Order ${confirmed.id} confirmed! Invoice emailed to ${confirmed.customerEmail}'),
              ),
            ],
          ),
          backgroundColor: AppColors.confirmed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );

      // Automatically show the generated invoice
      InvoiceViewDialog.show(context, confirmed);
    }
  }

  void _showCancelDialog(OrderModel order) {
    final reasonController = TextEditingController(text: 'Customer declined order during call');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel order ${order.id}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'e.g. Out of stock, customer unreachable, customer cancelled',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OrderProvider>().cancelOrder(order.id, reasonController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order ${order.id} has been cancelled.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.getOrderById(widget.orderId);

    if (order == null) {
      return const SizedBox.shrink();
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isPending = order.status == OrderStatus.pendingCall;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Top drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order ${order.id}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 10),
                            _statusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Placed: ${dateFormat.format(order.createdAt)}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (order.status == OrderStatus.confirmed)
                      OutlinedButton.icon(
                        onPressed: () => InvoiceViewDialog.show(context, order),
                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                        label: const Text('View Bill'),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Sheet Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Section 1: Customer Contact & Offline Call Action
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.contact_phone_rounded, color: AppColors.primary, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                'CUSTOMER & CALL VERIFICATION',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              if (order.isEmailSent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.confirmedBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Email Dispatched', style: TextStyle(fontSize: 11, color: AppColors.confirmed, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.customerName,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_rounded, size: 15, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          order.customerPhone,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.mail_outline_rounded, size: 15, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          order.customerEmail,
                                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Big Call Button
                              ElevatedButton.icon(
                                onPressed: () => _triggerCall(order),
                                icon: const Icon(Icons.phone_forwarded_rounded, size: 20),
                                label: const Text('Call Customer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.confirmed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 14),

                          // Call verification status selector & notes
                          Row(
                            children: [
                              const Text('Call Status: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<CallStatus>(
                                  initialValue: _selectedCallStatus,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: CallStatus.values.map((s) {
                                    return DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 13)));
                                  }).toList(),
                                  onChanged: isPending
                                      ? (val) {
                                          if (val != null) {
                                            setState(() => _selectedCallStatus = val);
                                            orderProvider.updateCallNotes(order.id, val, _callNotesController.text);
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _callNotesController,
                            enabled: isPending,
                            decoration: InputDecoration(
                              labelText: 'Pharmacist Call Notes',
                              hintText: 'e.g. Customer confirmed items; agreed on evening delivery',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              suffixIcon: isPending
                                  ? IconButton(
                                      icon: const Icon(Icons.save_rounded, size: 18),
                                      tooltip: 'Save Notes',
                                      onPressed: () {
                                        orderProvider.updateCallNotes(
                                          order.id,
                                          _selectedCallStatus ?? CallStatus.notCalled,
                                          _callNotesController.text,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Notes updated'), duration: Duration(seconds: 1)),
                                        );
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Delivery Mode & Location
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: order.isHomeDelivery
                            ? Colors.orange.withValues(alpha: 0.08)
                            : (isDark ? AppColors.darkCard : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: order.isHomeDelivery
                              ? Colors.orange.withValues(alpha: 0.3)
                              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                order.isHomeDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded,
                                color: order.isHomeDelivery ? Colors.deepOrange : AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order.isHomeDelivery ? 'HOME DELIVERY ORDER' : 'STORE PICKUP',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: order.isHomeDelivery ? Colors.deepOrange : AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (order.isHomeDelivery) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 18, color: Colors.deepOrange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    order.deliveryAddress ?? 'No specific address provided',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Manual Delivery Charge Input Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Set Delivery Charge (Manual by Admin)',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.deepOrange),
                                        ),
                                        Text(
                                          'Enter charge agreed during phone call',
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: TextField(
                                      controller: _deliveryChargeController,
                                      enabled: isPending,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        prefixText: '৳ ',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onChanged: (val) {
                                        final numVal = double.tryParse(val) ?? 0.0;
                                        orderProvider.setDeliveryCharge(order.id, numVal);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Customer selected Store Pickup. No delivery charge applies.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Ordered Items with Modify Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medication_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ORDER ITEMS (${order.items.length})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                        // Modify / Add Medicines Button
                        if (isPending)
                          ElevatedButton.icon(
                            onPressed: () => OrderEditItemsDialog.show(context, order.id),
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: const Text('Add / Modify Items'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.primaryDark,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Items Table/Cards
                    ...order.items.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    Text('${item.unit} • ৳${item.unitPrice.toStringAsFixed(2)} each', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(width: 16),
                              Text('৳${item.itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Section 4: Billing Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Medicines Subtotal:'),
                              Text('৳${order.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          if (order.isHomeDelivery) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Home Delivery Charge:', style: TextStyle(color: Colors.deepOrange)),
                                Text('৳${order.deliveryCharge.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.deepOrange)),
                              ],
                            ),
                          ],
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL PAYABLE:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              Text(
                                '৳${order.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions Row
                    if (isPending) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCancelDialog(order),
                              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                              label: const Text('Cancel Order', style: TextStyle(color: Colors.redAccent)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => _confirmOrder(order),
                              icon: const Icon(Icons.check_circle_rounded),
                              label: const Text('Confirm Order & Send Bill to Email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (order.status == OrderStatus.confirmed) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => InvoiceViewDialog.show(context, order),
                              icon: const Icon(Icons.receipt_long_rounded),
                              label: const Text('View Official Invoice'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                orderProvider.markDelivered(order.id);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Order ${order.id} marked as Delivered!'), backgroundColor: AppColors.delivered),
                                );
                              },
                              icon: const Icon(Icons.local_shipping_rounded),
                              label: const Text('Mark as Delivered'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.delivered, padding: const EdgeInsets.symmetric(vertical: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(OrderStatus status) {
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
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
