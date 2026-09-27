import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';

class NotificationService {
  /// Attempt to launch phone call or copy to clipboard on desktop
  static Future<bool> callCustomer(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (_) {
      // Fallback
    }

    // On Windows desktop or devices without dialer, copy to clipboard
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    return false;
  }

  /// Launch email client with pre-filled bill
  static Future<bool> sendEmailToCustomer({
    required String email,
    required String subject,
    required String body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (_) {
      // Fallback
    }

    await Clipboard.setData(ClipboardData(text: email));
    return false;
  }

  /// Format an invoice email body for an order
  static String generateInvoiceEmailContent(OrderModel order) {
    final buffer = StringBuffer();
    buffer.writeln('Dear ${order.customerName},\n');
    buffer.writeln('Thank you for ordering with EzzeMedicine Pharmacy.');
    buffer.writeln('Your order has been verified and confirmed by our pharmacist.\n');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('INVOICE / BILL DETAILS');
    buffer.writeln('Order ID: ${order.id}');
    buffer.writeln('Date: ${order.confirmedAt ?? order.createdAt}');
    buffer.writeln('Customer: ${order.customerName}');
    buffer.writeln('Phone: ${order.customerPhone}');
    buffer.writeln('Delivery Type: ${order.isHomeDelivery ? "Home Delivery" : "Store Pickup"}');
    if (order.isHomeDelivery && order.deliveryAddress != null) {
      buffer.writeln('Delivery Address: ${order.deliveryAddress}');
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('ITEMS:');

    for (final item in order.items) {
      buffer.writeln(
          '- ${item.medicineName} (${item.unit}) x${item.quantity} = ৳${item.itemTotal.toStringAsFixed(2)}');
    }

    buffer.writeln('--------------------------------------------------');
    buffer.writeln('Items Subtotal: ৳${order.subtotal.toStringAsFixed(2)}');
    if (order.isHomeDelivery) {
      buffer.writeln('Home Delivery Charge: ৳${order.deliveryCharge.toStringAsFixed(2)}');
    }
    buffer.writeln('GRAND TOTAL: ৳${order.totalAmount.toStringAsFixed(2)}');
    buffer.writeln('--------------------------------------------------\n');
    buffer.writeln('If you have any questions, please contact us at +880 1711-000000.');
    buffer.writeln('EzzeMedicine Pharmacy & Healthcare');

    return buffer.toString();
  }
}
