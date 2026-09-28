import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/sql_schema.dart';
import '../core/supabase_config.dart';
import '../models/medicine_model.dart';
import '../models/order_model.dart';
import '../models/report_model.dart';

class _TempMedicineAgg {
  final String medicineId;
  final String medicineName;
  final String category;
  int quantity;
  double totalRevenue;

  _TempMedicineAgg({
    required this.medicineId,
    required this.medicineName,
    required this.category,
    required this.quantity,
    required this.totalRevenue,
  });
}

class OrderService {
  static const String ordersTable = SupabaseSqlSchema.ordersTable;
  static const String orderItemsTable = SupabaseSqlSchema.orderItemsTable;

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => List.unmodifiable(_orders);
  RealtimeChannel? _realtimeChannel;

  OrderService() {
    _orders = List.from(OrderModel.sampleOrders);
  }

  /// Subscribe to realtime changes on orders table
  void subscribeToRealtime({required VoidCallback onOrdersUpdated}) {
    final client = SupabaseConfig.client;
    if (client == null || SupabaseConfig.useMockMode) return;

    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = client
          .channel('public:ezze_admin_orders')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: ordersTable,
            callback: (payload) {
              debugPrint('⚡ Realtime Order Change received: ${payload.eventType}');
              onOrdersUpdated();
            },
          )
          .subscribe();
      debugPrint('✅ Subscribed to Realtime changes on $ordersTable');
    } catch (e) {
      debugPrint('Realtime order subscription note: $e');
    }
  }

  void disposeRealtime() {
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    } catch (_) {}
  }

  /// Fetch orders from Supabase or Local Mock
  Future<List<OrderModel>> fetchOrders() async {
    final client = SupabaseConfig.client;

    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        final response = await client
            .from(ordersTable)
            .select('*, $orderItemsTable(*)')
            .order('created_at', ascending: false);

        final List<dynamic> data = response as List<dynamic>;
        if (data.isNotEmpty) {
          _orders = data.map((json) {
            final itemsList = (json[orderItemsTable] as List<dynamic>?)
                    ?.map((i) => OrderItemModel.fromMap(i))
                    .toList() ??
                [];
            return OrderModel.fromMap(json, itemsList);
          }).toList();
          return _orders;
        } else {
          // If orders table is newly created and empty, auto seed initial sample orders
          for (final order in OrderModel.sampleOrders) {
            try {
              await client.from(ordersTable).insert(order.toMap());
              for (final item in order.items) {
                await client.from(orderItemsTable).insert(item.toMap(order.id));
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Supabase fetchOrders note (using local cache if table not ready): $e');
      }
    }

    return _orders;
  }

  /// Compute monthly sales analysis report
  MonthlySalesReport getMonthlyReport(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final monthOrders = _orders.where((o) {
      final isCompleted = o.status == OrderStatus.confirmed || o.status == OrderStatus.delivered;
      return isCompleted && o.createdAt.year == year && o.createdAt.month == month;
    }).toList();

    double totalRevenue = 0.0;
    int totalUnitsSold = 0;
    double totalDeliveryCharges = 0.0;

    final Map<int, double> dailyIncomeMap = {for (int d = 1; d <= daysInMonth; d++) d: 0.0};
    final Map<int, int> dailyOrderCountMap = {for (int d = 1; d <= daysInMonth; d++) d: 0};
    final Map<String, _TempMedicineAgg> medMap = {};

    for (final order in monthOrders) {
      totalRevenue += order.totalAmount;
      totalDeliveryCharges += order.deliveryCharge;
      final day = order.createdAt.day;
      if (day >= 1 && day <= daysInMonth) {
        dailyIncomeMap[day] = (dailyIncomeMap[day] ?? 0.0) + order.totalAmount;
        dailyOrderCountMap[day] = (dailyOrderCountMap[day] ?? 0) + 1;
      }

      for (final item in order.items) {
        totalUnitsSold += item.quantity;
        if (!medMap.containsKey(item.medicineName)) {
          medMap[item.medicineName] = _TempMedicineAgg(
            medicineId: item.medicineId,
            medicineName: item.medicineName,
            category: 'Medicine',
            quantity: item.quantity,
            totalRevenue: item.itemTotal,
          );
        } else {
          final existing = medMap[item.medicineName]!;
          existing.quantity += item.quantity;
          existing.totalRevenue += item.itemTotal;
        }
      }
    }

    final dailyMetrics = List.generate(daysInMonth, (i) {
      final day = i + 1;
      return DailySalesMetric(
        day: day,
        date: DateTime(year, month, day),
        totalIncome: dailyIncomeMap[day] ?? 0.0,
        orderCount: dailyOrderCountMap[day] ?? 0,
      );
    });

    final topList = medMap.values.toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final top10 = topList.take(10).map((t) {
      final pct = totalRevenue > 0 ? (t.totalRevenue / totalRevenue) * 100 : 0.0;
      return TopSoldMedicine(
        medicineId: t.medicineId,
        medicineName: t.medicineName,
        category: t.category,
        quantitySold: t.quantity,
        totalRevenue: t.totalRevenue,
        percentageOfTotalSales: pct,
      );
    }).toList();

    final avgOrderValue = monthOrders.isNotEmpty ? (totalRevenue / monthOrders.length) : 0.0;

    return MonthlySalesReport(
      year: year,
      month: month,
      totalRevenue: totalRevenue,
      totalOrders: monthOrders.length,
      totalUnitsSold: totalUnitsSold,
      averageOrderValue: avgOrderValue,
      totalDeliveryCharges: totalDeliveryCharges,
      dailyMetrics: dailyMetrics,
      topSoldMedicines: top10,
    );
  }

  /// Create new order (e.g. from public website or simulated by admin)
  Future<OrderModel> createOrder({
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required bool isHomeDelivery,
    String? deliveryAddress,
    required List<OrderItemModel> items,
  }) async {
    final orderId = 'EZM-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final order = OrderModel(
      id: orderId,
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      customerEmail: customerEmail.trim(),
      isHomeDelivery: isHomeDelivery,
      deliveryAddress: isHomeDelivery ? deliveryAddress?.trim() : null,
      deliveryCharge: 0.0,
      status: OrderStatus.pendingCall,
      callStatus: CallStatus.notCalled,
      items: items,
    );

    final client = SupabaseConfig.client;
    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        await client.from(ordersTable).insert(order.toMap());
        for (final item in items) {
          await client.from(orderItemsTable).insert(item.toMap(orderId));
        }
      } catch (e) {
        debugPrint('Supabase createOrder error: $e');
      }
    }

    _orders.insert(0, order);
    return order;
  }

  /// Update call verification notes and call status
  Future<OrderModel> updateCallDetails({
    required String orderId,
    required CallStatus callStatus,
    String? callNotes,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final updated = _orders[index].copyWith(
      callStatus: callStatus,
      callNotes: callNotes ?? _orders[index].callNotes,
    );

    await _syncOrderUpdate(updated);
    _orders[index] = updated;
    return updated;
  }

  /// Modify order items during call (add, remove, or change qty)
  Future<OrderModel> updateOrderItems({
    required String orderId,
    required List<OrderItemModel> updatedItems,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final order = _orders[index];
    final updated = order.copyWith(
      items: updatedItems,
      callStatus: CallStatus.calledModified,
    );

    await _syncOrderUpdate(updated);
    _orders[index] = updated;
    return updated;
  }

  /// Add a medicine into existing order (when customer asks on the call)
  Future<OrderModel> addMedicineToOrder({
    required String orderId,
    required MedicineModel medicine,
    int quantity = 1,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final order = _orders[index];
    final items = List<OrderItemModel>.from(order.items);

    final existingIndex = items.indexWhere((i) => i.medicineId == medicine.id);
    if (existingIndex != -1) {
      final existing = items[existingIndex];
      items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      items.add(OrderItemModel(
        medicineId: medicine.id,
        medicineName: medicine.name,
        unit: medicine.unit,
        unitPrice: medicine.price,
        quantity: quantity,
        imageUrl: medicine.imageUrl,
      ));
    }

    return await updateOrderItems(orderId: orderId, updatedItems: items);
  }

  /// Set Home Delivery manual charge
  Future<OrderModel> setDeliveryCharge({
    required String orderId,
    required double charge,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final updated = _orders[index].copyWith(
      deliveryCharge: charge,
    );

    await _syncOrderUpdate(updated);
    _orders[index] = updated;
    return updated;
  }

  /// Confirm Order & Dispatch Bill to customer email
  Future<OrderModel> confirmOrder({
    required String orderId,
    double? manualDeliveryCharge,
    String? finalCallNotes,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final order = _orders[index];
    final deliveryFee = manualDeliveryCharge ?? order.deliveryCharge;

    final updated = order.copyWith(
      status: OrderStatus.confirmed,
      deliveryCharge: deliveryFee,
      confirmedAt: DateTime.now(),
      isEmailSent: true,
      emailSentAt: DateTime.now(),
      callNotes: finalCallNotes ?? order.callNotes,
      callStatus: order.callStatus == CallStatus.notCalled
          ? CallStatus.calledConfirmed
          : order.callStatus,
    );

    await _syncOrderUpdate(updated);
    _orders[index] = updated;
    return updated;
  }

  /// Cancel Order
  Future<OrderModel> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final updated = _orders[index].copyWith(
      status: OrderStatus.cancelled,
      cancellationReason: reason,
    );

    await _syncOrderUpdate(updated);
    _orders[index] = updated;
    return updated;
  }

  /// Mark order as Delivered
  Future<OrderModel> markAsDelivered(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final updated = _orders[index].copyWith(
      status: OrderStatus.delivered,
      deliveredAt: DateTime.now(),
    );

    await _syncOrderUpdate(updated);
    _orders[index] = updated;
    return updated;
  }

  /// Helper to sync changes to Supabase if connected
  Future<void> _syncOrderUpdate(OrderModel order) async {
    final client = SupabaseConfig.client;
    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        await client
            .from(ordersTable)
            .update(order.toMap())
            .eq('id', order.id);

        await client.from(orderItemsTable).delete().eq('order_id', order.id);
        for (final item in order.items) {
          await client.from(orderItemsTable).insert(item.toMap(order.id));
        }
      } catch (e) {
        debugPrint('Supabase _syncOrderUpdate error: $e');
      }
    }
  }
}
