import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/order_model.dart';
import '../../services/notification_service.dart';

class InvoiceViewDialog extends StatelessWidget {
  final OrderModel order;

  const InvoiceViewDialog({super.key, required this.order});

  static void show(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => InvoiceViewDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 820),
        child: Column(
          children: [
            // Top action bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Official Invoice / Bill',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Copy Bill Details',
                    onPressed: () {
                      final content = NotificationService.generateInvoiceEmailContent(order);
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable invoice content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pharmacy Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.storeName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppConstants.storeAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                'Phone: ${AppConstants.storePhone} • Email: ${AppConstants.storeEmail}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: order.status == OrderStatus.confirmed
                                ? AppColors.confirmedBg
                                : AppColors.pendingBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: order.status == OrderStatus.confirmed
                                  ? AppColors.confirmed
                                  : AppColors.pending,
                            ),
                          ),
                          child: Text(
                            order.status.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: order.status == OrderStatus.confirmed
                                  ? AppColors.confirmed
                                  : AppColors.pending,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Invoice Metadata Row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'INVOICE NO.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'INV-${order.id}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DATE & TIME',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateFormat.format(order.confirmedAt ?? order.createdAt),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PAYMENT METHOD',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Cash on Delivery / Pickup',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Customer Details Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BILLED TO CUSTOMER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                order.customerName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                order.customerPhone,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                order.customerEmail,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                order.isHomeDelivery ? Icons.home_rounded : Icons.store_mall_directory_rounded,
                                size: 16,
                                color: order.isHomeDelivery ? Colors.orange : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.isHomeDelivery
                                      ? 'Home Delivery: ${order.deliveryAddress ?? "Address not provided"}'
                                      : 'Store Pickup: Customer will collect from store',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: order.isHomeDelivery ? FontWeight.w600 : FontWeight.w500,
                                    color: order.isHomeDelivery ? Colors.deepOrange : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Itemized Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 4, child: Text('Medicine Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                          Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Item Rows
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.medicineName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.unit,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '৳${item.unitPrice.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'x${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '৳${item.itemTotal.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 24),

                    // Financial totals
                    Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Items Subtotal:', style: TextStyle(fontSize: 13)),
                                Text('৳${order.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (order.isHomeDelivery) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Home Delivery Charge (Manual):', style: TextStyle(fontSize: 13, color: Colors.deepOrange)),
                                  Text(
                                    '৳${order.deliveryCharge.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.deepOrange),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'GRAND TOTAL:',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '৳${order.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Email Confirmation Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: order.isEmailSent
                            ? AppColors.confirmed.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: order.isEmailSent
                              ? AppColors.confirmed.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            order.isEmailSent ? Icons.mark_email_read_rounded : Icons.mail_outline_rounded,
                            color: order.isEmailSent ? AppColors.confirmed : Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.isEmailSent
                                      ? 'Bill Sent to Customer Email'
                                      : 'Email Not Dispatched Yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: order.isEmailSent ? AppColors.confirmed : Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.isEmailSent
                                      ? 'Automated invoice receipt was delivered to ${order.customerEmail}'
                                      : 'Will be dispatched upon order confirmation by admin.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final content = NotificationService.generateInvoiceEmailContent(order);
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bill text copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Bill'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Done'),
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
