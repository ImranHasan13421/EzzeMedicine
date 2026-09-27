import 'package:flutter/foundation.dart';
import '../core/sql_schema.dart';
import '../core/supabase_config.dart';
import '../models/medicine_model.dart';
import '../models/order_model.dart';

class OrderService {
  static const String ordersTable = SupabaseSqlSchema.ordersTable;
  static const String orderItemsTable = SupabaseSqlSchema.orderItemsTable;

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => List.unmodifiable(_orders);

  OrderService() {
    _orders = List.from(OrderModel.sampleOrders);
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
