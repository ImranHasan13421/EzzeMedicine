import 'package:uuid/uuid.dart';

enum OrderStatus {
  pendingCall,
  confirmed,
  cancelled,
  delivered;

  String get label {
    switch (this) {
      case OrderStatus.pendingCall:
        return 'Pending Verification';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  static OrderStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      case 'delivered':
        return OrderStatus.delivered;
      case 'pending_call':
      case 'pendingcall':
      default:
        return OrderStatus.pendingCall;
    }
  }

  String toDbString() {
    switch (this) {
      case OrderStatus.pendingCall:
        return 'pending_call';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.delivered:
        return 'delivered';
    }
  }
}

enum CallStatus {
  notCalled,
  calledConfirmed,
  calledModified,
  unreachable;

  String get label {
    switch (this) {
      case CallStatus.notCalled:
        return 'Not Called Yet';
      case CallStatus.calledConfirmed:
        return 'Verified via Call';
      case CallStatus.calledModified:
        return 'Items Modified on Call';
      case CallStatus.unreachable:
        return 'Customer Unreachable';
    }
  }

  static CallStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'called_confirmed':
        return CallStatus.calledConfirmed;
      case 'called_modified':
        return CallStatus.calledModified;
      case 'unreachable':
        return CallStatus.unreachable;
      default:
        return CallStatus.notCalled;
    }
  }

  String toDbString() {
    switch (this) {
      case CallStatus.calledConfirmed:
        return 'called_confirmed';
      case CallStatus.calledModified:
        return 'called_modified';
      case CallStatus.unreachable:
        return 'unreachable';
      case CallStatus.notCalled:
        return 'not_called';
    }
  }
}

class OrderItemModel {
  final String id;
  final String medicineId;
  final String medicineName;
  final String unit;
  final double unitPrice;
  final int quantity;
  final double itemTotal;
  final String? imageUrl;

  OrderItemModel({
    String? id,
    required this.medicineId,
    required this.medicineName,
    this.unit = 'Strip',
    required this.unitPrice,
    required this.quantity,
    double? itemTotal,
    this.imageUrl,
  })  : id = id ?? const Uuid().v4(),
        itemTotal = itemTotal ?? (unitPrice * quantity);

  OrderItemModel copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    String? unit,
    double? unitPrice,
    int? quantity,
    double? itemTotal,
    String? imageUrl,
  }) {
    final qty = quantity ?? this.quantity;
    final price = unitPrice ?? this.unitPrice;
    return OrderItemModel(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      unit: unit ?? this.unit,
      unitPrice: price,
      quantity: qty,
      itemTotal: price * qty,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    final qty = (map['quantity'] as num?)?.toInt() ?? 1;
    final price = (map['unit_price'] as num?)?.toDouble() ?? 0.0;
    return OrderItemModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      medicineId: map['medicine_id']?.toString() ?? '',
      medicineName: map['medicine_name']?.toString() ?? '',
      unit: map['unit']?.toString() ?? 'Strip',
      unitPrice: price,
      quantity: qty,
      itemTotal: (map['item_total'] as num?)?.toDouble() ?? (price * qty),
      imageUrl: map['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toMap(String orderId) {
    return {
      'id': id,
      'order_id': orderId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'unit': unit,
      'unit_price': unitPrice,
      'quantity': quantity,
      'item_total': itemTotal,
      'image_url': imageUrl,
    };
  }
}

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final bool isHomeDelivery;
  final String? deliveryAddress;
  final double deliveryCharge; // Set manually by admin during call/confirmation!
  final OrderStatus status;
  final List<OrderItemModel> items;
  final double subtotal;
  final double totalAmount;
  final String? callNotes;
  final CallStatus callStatus;
  final bool isEmailSent;
  final DateTime? emailSentAt;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? cancellationReason;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.isHomeDelivery = false,
    this.deliveryAddress,
    this.deliveryCharge = 0.0,
    this.status = OrderStatus.pendingCall,
    required this.items,
    double? subtotal,
    double? totalAmount,
    this.callNotes,
    this.callStatus = CallStatus.notCalled,
    this.isEmailSent = false,
    this.emailSentAt,
    DateTime? createdAt,
    this.confirmedAt,
    this.cancellationReason,
  })  : createdAt = createdAt ?? DateTime.now(),
        subtotal = subtotal ?? items.fold<double>(0.0, (double sum, item) => sum + item.itemTotal),
        totalAmount = totalAmount ??
            (items.fold<double>(0.0, (double sum, item) => sum + item.itemTotal) + deliveryCharge);

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    bool? isHomeDelivery,
    String? deliveryAddress,
    double? deliveryCharge,
    OrderStatus? status,
    List<OrderItemModel>? items,
    double? subtotal,
    double? totalAmount,
    String? callNotes,
    CallStatus? callStatus,
    bool? isEmailSent,
    DateTime? emailSentAt,
    DateTime? createdAt,
    DateTime? confirmedAt,
    String? cancellationReason,
  }) {
    final updatedItems = items ?? this.items;
    final updatedDeliveryCharge = deliveryCharge ?? this.deliveryCharge;
    final calculatedSubtotal = subtotal ?? updatedItems.fold<double>(0.0, (double sum, i) => sum + i.itemTotal);
    final calculatedTotal = totalAmount ?? (calculatedSubtotal + updatedDeliveryCharge);

    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      isHomeDelivery: isHomeDelivery ?? this.isHomeDelivery,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryCharge: updatedDeliveryCharge,
      status: status ?? this.status,
      items: updatedItems,
      subtotal: calculatedSubtotal,
      totalAmount: calculatedTotal,
      callNotes: callNotes ?? this.callNotes,
      callStatus: callStatus ?? this.callStatus,
      isEmailSent: isEmailSent ?? this.isEmailSent,
      emailSentAt: emailSentAt ?? this.emailSentAt,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, [List<OrderItemModel>? items]) {
    final orderItems = items ?? [];
    final double sub = (map['subtotal'] as num?)?.toDouble() ??
        orderItems.fold<double>(0.0, (double sum, item) => sum + item.itemTotal);
    final double delFee = (map['delivery_charge'] as num?)?.toDouble() ?? 0.0;

    return OrderModel(
      id: map['id']?.toString() ?? 'EZM-${DateTime.now().millisecondsSinceEpoch % 10000}',
      customerName: map['customer_name']?.toString() ?? '',
      customerPhone: map['customer_phone']?.toString() ?? '',
      customerEmail: map['customer_email']?.toString() ?? '',
      isHomeDelivery: map['is_home_delivery'] == true,
      deliveryAddress: map['delivery_address']?.toString(),
      deliveryCharge: delFee,
      status: OrderStatus.fromString(map['status']?.toString()),
      items: orderItems,
      subtotal: sub,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? (sub + delFee),
      callNotes: map['call_notes']?.toString(),
      callStatus: CallStatus.fromString(map['call_status']?.toString()),
      isEmailSent: map['is_email_sent'] == true,
      emailSentAt: map['email_sent_at'] != null
          ? DateTime.tryParse(map['email_sent_at'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      confirmedAt: map['confirmed_at'] != null
          ? DateTime.tryParse(map['confirmed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'is_home_delivery': isHomeDelivery,
      'delivery_address': deliveryAddress,
      'delivery_charge': deliveryCharge,
      'status': status.toDbString(),
      'subtotal': subtotal,
      'total_amount': totalAmount,
      'call_notes': callNotes,
      'call_status': callStatus.toDbString(),
      'is_email_sent': isEmailSent,
      'email_sent_at': emailSentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
    };
  }

  /// Initial sample orders to immediately demonstrate the workflow
  static List<OrderModel> get sampleOrders => [
        OrderModel(
          id: 'EZM-1024',
          customerName: 'Tariqul Islam',
          customerPhone: '+880 1819-234567',
          customerEmail: 'tariqul.islam@gmail.com',
          isHomeDelivery: true,
          deliveryAddress: 'Flat 4B, House 18, Road 7, Dhanmondi, Dhaka',
          deliveryCharge: 0.0, // Pending admin manual charge setting
          status: OrderStatus.pendingCall,
          callStatus: CallStatus.notCalled,
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          items: [
            OrderItemModel(
              medicineId: 'med-001',
              medicineName: 'Napa Extra',
              unit: 'Strip (10 pcs)',
              unitPrice: 35.0,
              quantity: 2,
              itemTotal: 70.0,
            ),
            OrderItemModel(
              medicineId: 'med-004',
              medicineName: 'Tusca Cold & Cough',
              unit: 'Bottle (100ml)',
              unitPrice: 95.0,
              quantity: 1,
              itemTotal: 95.0,
            ),
          ],
        ),
        OrderModel(
          id: 'EZM-1025',
          customerName: 'Fatema Begum',
          customerPhone: '+880 1712-987654',
          customerEmail: 'fatema.begum92@yahoo.com',
          isHomeDelivery: false, // Store pickup
          deliveryAddress: null,
          deliveryCharge: 0.0,
          status: OrderStatus.pendingCall,
          callStatus: CallStatus.notCalled,
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
          items: [
            OrderItemModel(
              medicineId: 'med-002',
              medicineName: 'Sergel 20mg',
              unit: 'Strip (10 pcs)',
              unitPrice: 70.0,
              quantity: 3,
              itemTotal: 210.0,
            ),
            OrderItemModel(
              medicineId: 'med-006',
              medicineName: 'Bextram Gold Multivitamin',
              unit: 'Bottle (200ml)',
              unitPrice: 320.0,
              quantity: 1,
              itemTotal: 320.0,
            ),
          ],
        ),
        OrderModel(
          id: 'EZM-1022',
          customerName: 'Kamrul Hasan',
          customerPhone: '+880 1911-345678',
          customerEmail: 'kamrul.hasan@outlook.com',
          isHomeDelivery: true,
          deliveryAddress: 'House 5, Lane 3, Block C, Mirpur 12, Dhaka',
          deliveryCharge: 60.0, // Admin manually set delivery fee
          status: OrderStatus.confirmed,
          callStatus: CallStatus.calledModified,
          callNotes: 'Customer requested 1 extra strip of Napa Extra during phone call.',
          isEmailSent: true,
          emailSentAt: DateTime.now().subtract(const Duration(hours: 2)),
          confirmedAt: DateTime.now().subtract(const Duration(hours: 2)),
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          items: [
            OrderItemModel(
              medicineId: 'med-001',
              medicineName: 'Napa Extra',
              unit: 'Strip (10 pcs)',
              unitPrice: 35.0,
              quantity: 3,
              itemTotal: 105.0,
            ),
            OrderItemModel(
              medicineId: 'med-002',
              medicineName: 'Sergel 20mg',
              unit: 'Strip (10 pcs)',
              unitPrice: 70.0,
              quantity: 2,
              itemTotal: 140.0,
            ),
          ],
        ),
      ];
}
