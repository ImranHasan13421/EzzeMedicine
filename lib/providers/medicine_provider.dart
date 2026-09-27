import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../services/medicine_service.dart';

class MedicineProvider extends ChangeNotifier {
  final MedicineService _service;
  List<MedicineModel> _medicines = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;

  MedicineProvider({MedicineService? service}) : _service = service ?? MedicineService() {
    loadMedicines();
  }

  List<MedicineModel> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  int get totalCount => _medicines.length;
  int get lowStockCount => _medicines.where((m) => m.isLowStock).length;
  int get outOfStockCount => _medicines.where((m) => m.isOutOfStock).length;

  List<MedicineModel> get filteredMedicines {
    return _medicines.where((med) {
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory == 'All' ||
          med.category.toLowerCase() == _selectedCategory!.toLowerCase();

      if (!matchesCategory) return false;

      if (_searchQuery.trim().isEmpty) return true;

      final q = _searchQuery.toLowerCase();
      return med.name.toLowerCase().contains(q) ||
          med.genericName.toLowerCase().contains(q) ||
          med.manufacturer.toLowerCase().contains(q) ||
          med.strength.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();
    try {
      _medicines = await _service.fetchMedicines();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<bool> addMedicine(MedicineModel medicine) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addMedicine(medicine);
      _medicines = await _service.fetchMedicines();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedicine(MedicineModel medicine) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateMedicine(medicine);
      _medicines = await _service.fetchMedicines();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    try {
      await _service.deleteMedicine(id);
      _medicines.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> adjustStock(String id, int delta) async {
    await _service.adjustStock(id, delta);
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      final current = _medicines[index];
      final newQty = (current.stockQuantity + delta).clamp(0, 99999);
      _medicines[index] = current.copyWith(stockQuantity: newQty);
      notifyListeners();
    }
  }

  Future<String?> uploadImage(Uint8List bytes, String filename) async {
    return await _service.uploadMedicineImage(fileBytes: bytes, fileName: filename);
  }
}
