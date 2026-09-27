import 'package:flutter/foundation.dart';
import '../core/sql_schema.dart';
import '../core/supabase_config.dart';
import '../models/medicine_model.dart';

class MedicineService {
  static const String tableName = SupabaseSqlSchema.medicinesTable;

  List<MedicineModel> _medicines = [];
  List<MedicineModel> get medicines => List.unmodifiable(_medicines);

  MedicineService() {
    _medicines = List.from(MedicineModel.sampleMedicines);
  }

  /// Load all medicines from Supabase or Local Mock
  Future<List<MedicineModel>> fetchMedicines() async {
    final client = SupabaseConfig.client;

    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        final response = await client
            .from(tableName)
            .select()
            .order('created_at', ascending: false);

        final List<dynamic> data = response as List<dynamic>;
        if (data.isNotEmpty) {
          _medicines = data.map((json) => MedicineModel.fromMap(json)).toList();
          return _medicines;
        } else {
          // If table is newly created and empty, automatically seed initial medicines!
          for (final med in MedicineModel.sampleMedicines) {
            try {
              await client.from(tableName).insert(med.toMap());
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Supabase fetchMedicines note (using local cache if table not ready): $e');
      }
    }

    return _medicines;
  }

  /// Add new medicine
  Future<MedicineModel> addMedicine(MedicineModel medicine) async {
    final client = SupabaseConfig.client;

    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        final inserted = await client
            .from(tableName)
            .insert(medicine.toMap())
            .select()
            .single();
        final created = MedicineModel.fromMap(inserted);
        _medicines.insert(0, created);
        return created;
      } catch (e) {
        debugPrint('Supabase addMedicine error: $e');
      }
    }

    _medicines.insert(0, medicine);
    return medicine;
  }

  /// Update existing medicine
  Future<MedicineModel> updateMedicine(MedicineModel medicine) async {
    final client = SupabaseConfig.client;

    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        await client
            .from(tableName)
            .update(medicine.toMap())
            .eq('id', medicine.id);
      } catch (e) {
        debugPrint('Supabase updateMedicine error: $e');
      }
    }

    final index = _medicines.indexWhere((m) => m.id == medicine.id);
    if (index != -1) {
      _medicines[index] = medicine;
    }
    return medicine;
  }

  /// Delete medicine
  Future<bool> deleteMedicine(String id) async {
    final client = SupabaseConfig.client;

    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        await client.from(tableName).delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase deleteMedicine error: $e');
      }
    }

    _medicines.removeWhere((m) => m.id == id);
    return true;
  }

  /// Quick stock increment or decrement
  Future<void> adjustStock(String id, int delta) async {
    final index = _medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      final current = _medicines[index];
      final newQuantity = (current.stockQuantity + delta).clamp(0, 99999);
      final updated = current.copyWith(stockQuantity: newQuantity);
      await updateMedicine(updated);
    }
  }

  /// Upload medicine image to Supabase Storage bucket
  Future<String?> uploadMedicineImage({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final client = SupabaseConfig.client;
    if (client != null && !SupabaseConfig.useMockMode) {
      try {
        final path = 'medicines/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        await client.storage.from('medicine_images').uploadBinary(
              path,
              fileBytes,
            );
        final publicUrl = client.storage.from('medicine_images').getPublicUrl(path);
        return publicUrl;
      } catch (e) {
        debugPrint('Supabase upload image error: $e');
      }
    }
    return null;
  }
}
