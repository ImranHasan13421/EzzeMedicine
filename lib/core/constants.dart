import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'EzzeMedicine Admin';
  static const String appTagline = 'Smart Pharmacy & Order Management System';
  static const String currencySymbol = '৳'; // Default to BDT (configurable)

  // Store information for billing & invoices
  static const String storeName = 'EzzeMedicine Pharmacy & Healthcare';
  static const String storeAddress = 'Holding 42, Road 11, Dhanmondi, Dhaka';
  static const String storePhone = '+880 1711-000000';
  static const String storeEmail = 'admin@ezzemedicine.com';
  static const String storeWebsite = 'www.ezzemedicine.com';

  // Medicine Categories
  static const List<String> medicineCategories = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Suspension',
    'Injection',
    'Ointment / Cream',
    'Eye & Ear Drops',
    'Inhaler',
    'Suppository',
    'Healthcare & Device',
    'Vitamins & Supplements',
  ];

  // Packaging units
  static const List<String> medicineUnits = [
    'Strip (10 pcs)',
    'Box',
    'Bottle (100ml)',
    'Bottle (200ml)',
    'Bottle (60ml)',
    'Vial / Ampoule',
    'Tube',
    'Piece',
  ];
}

class AppColors {
  // Primary Teal / Emerald brand
  static const Color primary = Color(0xFF00796B);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFFE0F2F1);
  static const Color accent = Color(0xFF26A69A);
  static const Color secondary = Color(0xFF0288D1);

  // Status colors
  static const Color pending = Color(0xFFE65100);
  static const Color pendingBg = Color(0xFFFFF3E0);
  static const Color confirmed = Color(0xFF2E7D32);
  static const Color confirmedBg = Color(0xFFE8F5E9);
  static const Color cancelled = Color(0xFFC62828);
  static const Color cancelledBg = Color(0xFFFFEBEE);
  static const Color delivered = Color(0xFF1565C0);
  static const Color deliveredBg = Color(0xFFE3F2FD);

  // Stock alerts
  static const Color lowStock = Color(0xFFD84315);
  static const Color lowStockBg = Color(0xFFFBE9E7);
  static const Color outOfStock = Color(0xFFB71C1C);

  // Neutral dark
  static const Color darkBg = Color(0xFF121820);
  static const Color darkSurface = Color(0xFF1B232E);
  static const Color darkCard = Color(0xFF232D3B);
  static const Color darkBorder = Color(0xFF2E3B4D);
}
