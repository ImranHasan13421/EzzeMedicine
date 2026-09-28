import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../models/order_model.dart';
import '../models/report_model.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service;
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  OrderStatus? _statusFilter;

  OrderProvider({OrderService? service}) : _service = service ?? OrderService() {
    loadOrders();
    _service.subscribeToRealtime(onOrdersUpdated: () {
      debugPrint('⚡ Realtime event received in OrderProvider: updating UI');
      loadOrders(silent: true);
    });
  }

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  OrderStatus? get statusFilter => _statusFilter;

  int get pendingCallsCount =>
      _orders.where((o) => o.status == OrderStatus.pendingCall).length;
  int get confirmedCount =>
      _orders.where((o) => o.status == OrderStatus.confirmed).length;
  int get deliveredCount =>
      _orders.where((o) => o.status == OrderStatus.delivered).length;
  int get cancelledCount =>
      _orders.where((o) => o.status == OrderStatus.cancelled).length;

  double get totalRevenue => _orders
      .where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.delivered)
      .fold(0.0, (sum, o) => sum + o.totalAmount);

  List<OrderModel> get filteredOrders {
    return _orders.where((order) {
      if (_statusFilter != null && order.status != _statusFilter) {
        return false;
      }

      if (_searchQuery.trim().isEmpty) return true;

      final q = _searchQuery.toLowerCase();
      final inId = order.id.toLowerCase().contains(q);
      final inName = order.customerName.toLowerCase().contains(q);
      final inPhone = order.customerPhone.toLowerCase().contains(q);
      final inEmail = order.customerEmail.toLowerCase().contains(q);
      final inItems = order.items.any((i) => i.medicineName.toLowerCase().contains(q));

      return inId || inName || inPhone || inEmail || inItems;
    }).toList();
  }

  Future<void> loadOrders({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _orders = await _service.fetchOrders();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    await loadOrders(silent: false);
  }

  MonthlySalesReport getMonthlyReport(int year, int month) {
    return _service.getMonthlyReport(year, month);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(OrderStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  OrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Trigger calling customer and record call action
  Future<bool> triggerCustomerCall(OrderModel order) async {
    final launched = await NotificationService.callCustomer(order.customerPhone);
    return launched;
  }

  /// Update call verification notes and call status
  Future<void> updateCallNotes(String orderId, CallStatus callStatus, String? notes) async {
    final updated = await _service.updateCallDetails(
      orderId: orderId,
      callStatus: callStatus,
      callNotes: notes,
    );
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = updated;
      notifyListeners();
    }
  }

  /// Add medicine to order on customer request during the call
  Future<void> addMedicineToOrder(String orderId, MedicineModel medicine, int qty) async {
    final updated = await _service.addMedicineToOrder(
      orderId: orderId,
      medicine: medicine,
      quantity: qty,
    );
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = updated;
      notifyListeners();
    }
  }

  /// Update item quantity in order
  Future<void> updateItemQuantity(String orderId, String itemId, int newQuantity) async {
    final order = getOrderById(orderId);
    if (order == null) return;

    final updatedItems = List<OrderItemModel>.from(order.items);
    if (newQuantity <= 0) {
      updatedItems.removeWhere((i) => i.id == itemId);
    } else {
      final itemIdx = updatedItems.indexWhere((i) => i.id == itemId);
      if (itemIdx != -1) {
        updatedItems[itemIdx] = updatedItems[itemIdx].copyWith(quantity: newQuantity);
      }
    }

    final updated = await _service.updateOrderItems(
      orderId: orderId,
      updatedItems: updatedItems,
    );
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = updated;
      notifyListeners();
    }
  }

  /// Remove item from order
  Future<void> removeItemFromOrder(String orderId, String itemId) async {
    await updateItemQuantity(orderId, itemId, 0);
  }

  /// Admin sets manual delivery charge for Home Delivery
  Future<void> setDeliveryCharge(String orderId, double charge) async {
    final updated = await _service.setDeliveryCharge(orderId: orderId, charge: charge);
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = updated;
      notifyListeners();
    }
  }

  /// Confirm Order & Dispatch Bill to customer email
  Future<OrderModel> confirmOrder({
    required String orderId,
    double? manualDeliveryCharge,
    String? notes,
  }) async {
    final updated = await _service.confirmOrder(
      orderId: orderId,
      manualDeliveryCharge: manualDeliveryCharge,
      finalCallNotes: notes,
    );
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  /// Cancel Order
  Future<void> cancelOrder(String orderId, String reason) async {
    final updated = await _service.cancelOrder(orderId: orderId, reason: reason);
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = updated;
      notifyListeners();
    }
  }

  /// Mark Delivered
  Future<void> markDelivered(String orderId) async {
    final updated = await _service.markAsDelivered(orderId);
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = updated;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.disposeRealtime();
    super.dispose();
  }
}
