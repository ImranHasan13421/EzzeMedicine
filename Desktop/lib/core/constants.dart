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
  // Medical Clinical Blue & White Palette
  static const Color primary = Color(0xFF0284C7); // Clinical Sky/Hospital Blue
  static const Color primaryDark = Color(0xFF0369A1); // Deep Hospital Blue
  static const Color primaryLight = Color(0xFFE0F2FE); // Soft Medical Blue Tint
  static const Color primarySoft = Color(0xFFF0F9FF); // Pristine Ice Blue
  static const Color accent = Color(0xFF2563EB); // Royal Clinical Blue
  static const Color secondary = Color(0xFF0EA5E9); // Bright Medical Cyan

  // Surface & Page Backgrounds
  static const Color scaffoldBg = Color(0xFFF8FAFC); // Clean clinical slate-white
  static const Color cardBg = Color(0xFFFFFFFF); // Pure white
  static const Color borderLight = Color(0xFFE2E8F0); // Subtle Slate Border

  // Status colors
  static const Color pending = Color(0xFFF59E0B);
  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color confirmed = Color(0xFF10B981);
  static const Color confirmedBg = Color(0xFFD1FAE5);
  static const Color cancelled = Color(0xFFEF4444);
  static const Color cancelledBg = Color(0xFFFEE2E2);
  static const Color delivered = Color(0xFF0284C7);
  static const Color deliveredBg = Color(0xFFE0F2FE);

  // Stock alerts
  static const Color lowStock = Color(0xFFF97316);
  static const Color lowStockBg = Color(0xFFFFEDD5);
  static const Color outOfStock = Color(0xFFDC2626);

  // Modern Dark Mode (Deep Slate Blue)
  static const Color darkBg = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF111D3B);
  static const Color darkCard = Color(0xFF1C2A4F);
  static const Color darkBorder = Color(0xFF2D3F6D);
}
