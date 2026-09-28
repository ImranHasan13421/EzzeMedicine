import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/order_provider.dart';

class OrderEditItemsDialog extends StatefulWidget {
  final String orderId;

  const OrderEditItemsDialog({super.key, required this.orderId});

  static void show(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OrderEditItemsDialog(orderId: orderId),
    );
  }

  @override
  State<OrderEditItemsDialog> createState() => _OrderEditItemsDialogState();
}

class _OrderEditItemsDialogState extends State<OrderEditItemsDialog> {
  String _catalogSearch = '';
  MedicineModel? _selectedMedicineToAdd;
  int _addQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderProvider = context.watch<OrderProvider>();
    final medProvider = context.watch<MedicineProvider>();
    final order = orderProvider.getOrderById(widget.orderId);

    if (order == null) {
      return const Dialog(child: Padding(padding: EdgeInsets.all(20), child: Text('Order not found')));
    }

    // Filtered catalog medicines for adding
    final availableMedicines = medProvider.medicines.where((m) {
      if (_catalogSearch.trim().isEmpty) return true;
      final q = _catalogSearch.toLowerCase();
      return m.name.toLowerCase().contains(q) ||
          m.genericName.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 850),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.playlist_add_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modify Order Items (On Call with Customer)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Order ${order.id} • ${order.customerName}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Active Order Items
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CURRENT ITEMS IN ORDER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '${order.items.length} items',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: order.items.isEmpty
                                ? Center(
                                    child: Text(
                                      'Order is currently empty.\nAdd medicines from the catalog on the right.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey.shade500),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: order.items.length,
                                    separatorBuilder: (context, index) => const Divider(height: 12),
                                    itemBuilder: (ctx, index) {
                                      final item = order.items[index];
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkCard : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
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
                                                  Text(
                                                    item.medicineName,
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${item.unit} • ৳${item.unitPrice.toStringAsFixed(2)} each',
                                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Total: ৳${item.itemTotal.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Quantity Controls
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                                  onPressed: () {
                                                    orderProvider.updateItemQuantity(order.id, item.id, item.quantity - 1);
                                                  },
                                                ),
                                                Text(
                                                  '${item.quantity}',
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                                                  onPressed: () {
                                                    orderProvider.updateItemQuantity(order.id, item.id, item.quantity + 1);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                                  tooltip: 'Remove',
                                                  onPressed: () {
                                                    orderProvider.removeItemFromOrder(order.id, item.id);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const Divider(height: 20),
                          // Live subtotal display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Items Subtotal:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '৳${order.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 18),
                    const VerticalDivider(width: 1),
                    const SizedBox(width: 18),

                    // Right Column: Add Medicine from Pharmacy Catalog
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ADD MEDICINE FROM CATALOG',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search catalog...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (val) => setState(() => _catalogSearch = val),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: availableMedicines.length,
                              itemBuilder: (ctx, i) {
                                final med = availableMedicines[i];
                                final isSelected = _selectedMedicineToAdd?.id == med.id;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedMedicineToAdd = med;
                                      _addQuantity = 1;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.12)
                                          : (isDark ? AppColors.darkCard : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                med.name,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                              ),
                                              Text(
                                                '${med.strength} • ৳${med.price.toStringAsFixed(2)}',
                                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (med.isOutOfStock)
                                          const Text('Out', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w700))
                                        else
                                          Text('Stock: ${med.stockQuantity}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Selected medicine add bar
                          if (_selectedMedicineToAdd != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedMedicineToAdd!.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        '৳${_selectedMedicineToAdd!.price.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Qty:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          if (_addQuantity > 1) setState(() => _addQuantity--);
                                        },
                                        child: const Icon(Icons.remove_circle_outline, size: 20),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text('$_addQuantity', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                      InkWell(
                                        onTap: () => setState(() => _addQuantity++),
                                        child: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed: () {
                                          orderProvider.addMedicineToOrder(
                                            order.id,
                                            _selectedMedicineToAdd!,
                                            _addQuantity,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added "${_selectedMedicineToAdd!.name}" to order'),
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                          setState(() {
                                            _selectedMedicineToAdd = null;
                                            _addQuantity = 1;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        child: const Text('Add to Order'),
                                      ),
                                    ],
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

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done Modifying'),
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
