import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';

class MedicineFormDialog extends StatefulWidget {
  final MedicineModel? medicineToEdit;

  const MedicineFormDialog({super.key, this.medicineToEdit});

  static void show(BuildContext context, {MedicineModel? medicine}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MedicineFormDialog(medicineToEdit: medicine),
    );
  }

  @override
  State<MedicineFormDialog> createState() => _MedicineFormDialogState();
}

class _MedicineFormDialogState extends State<MedicineFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _genericNameController;
  late TextEditingController _manufacturerController;
  late TextEditingController _strengthController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _stockController;
  late TextEditingController _minAlertController;
  late TextEditingController _descriptionController;
  late TextEditingController _dosageController;

  late String _selectedCategory;
  late String _selectedUnit;
  late bool _requiresPrescription;
  bool _isSaving = false;

  // Image State (Captured via camera or picked from storage)
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final m = widget.medicineToEdit;

    _nameController = TextEditingController(text: m?.name ?? '');
    _genericNameController = TextEditingController(text: m?.genericName ?? '');
    _manufacturerController = TextEditingController(text: m?.manufacturer ?? '');
    _strengthController = TextEditingController(text: m?.strength ?? '');
    _priceController = TextEditingController(text: m != null ? m.price.toString() : '');
    _costPriceController = TextEditingController(text: m != null ? m.costPrice.toString() : '');
    _stockController = TextEditingController(text: m != null ? m.stockQuantity.toString() : '50');
    _minAlertController = TextEditingController(text: m != null ? m.minStockAlert.toString() : '10');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _dosageController = TextEditingController(text: m?.dosageInstructions ?? '');

    _selectedCategory = m?.category ?? AppConstants.medicineCategories.first;
    _selectedUnit = m?.unit ?? AppConstants.medicineUnits.first;
    _requiresPrescription = m?.requiresPrescription ?? false;
    _currentImageUrl = m?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _manufacturerController.dispose();
    _strengthController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minAlertController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  /// Capture image from device camera (mobile phone)
  Future<void> _captureFromCamera() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = photo.name;
        });
      }
    } catch (e) {
      debugPrint('Camera capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera not available or permission denied: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Upload image from storage / file picker
  Future<void> _pickFromStorage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
        return;
      }
    } catch (e) {
      debugPrint('Gallery picker fallback to file picker: $e');
    }

    // Fallback to FilePicker (e.g. on Desktop)
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.xFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = file.name;
        });
      }
    } catch (e) {
      debugPrint('FilePicker error: $e');
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _currentImageUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final medProvider = context.read<MedicineProvider>();

    final price = double.tryParse(_priceController.text) ?? 0.0;
    final costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final minAlert = int.tryParse(_minAlertController.text) ?? 10;

    String? finalImageUrl = _currentImageUrl;

    // If new image was captured/uploaded, upload bytes to Supabase Storage
    if (_selectedImageBytes != null) {
      final uploadedUrl = await medProvider.uploadImage(
        _selectedImageBytes!,
        _selectedImageName ?? 'medicine_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        finalImageUrl = uploadedUrl;
      }
    }

    bool success;
    if (widget.medicineToEdit != null) {
      final updated = widget.medicineToEdit!.copyWith(
        name: _nameController.text.trim(),
        genericName: _genericNameController.text.trim(),
        category: _selectedCategory,
        manufacturer: _manufacturerController.text.trim(),
        strength: _strengthController.text.trim(),
        unit: _selectedUnit,
        price: price,
        costPrice: costPrice,
        stockQuantity: stock,
        minStockAlert: minAlert,
        imageUrl: finalImageUrl,
        requiresPrescription: _requiresPrescription,
        description: _descriptionController.text.trim(),
        dosageInstructions: _dosageController.text.trim(),
      );
      success = await medProvider.updateMedicine(updated);
    } else {
      final newMed = MedicineModel(
        name: _nameController.text.trim(),
        genericName: _genericNameController.text.trim(),
        category: _selectedCategory,
        manufacturer: _manufacturerController.text.trim(),
        strength: _strengthController.text.trim(),
        unit: _selectedUnit,
        price: price,
        costPrice: costPrice,
        stockQuantity: stock,
        minStockAlert: minAlert,
        imageUrl: finalImageUrl,
        requiresPrescription: _requiresPrescription,
        description: _descriptionController.text.trim(),
        dosageInstructions: _dosageController.text.trim(),
      );
      success = await medProvider.addMedicine(newMed);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.medicineToEdit != null
                  ? 'Medicine updated successfully'
                  : 'New medicine added to catalog',
            ),
            backgroundColor: AppColors.confirmed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save medicine'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.medicineToEdit != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Medicine Details' : 'Add New Medicine to Inventory',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Basic Identifiers
                      const Text(
                        'BASIC INFORMATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Brand / Medicine Name *',
                                hintText: 'e.g. Napa Extra, Sergel 20mg',
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _genericNameController,
                              decoration: const InputDecoration(
                                labelText: 'Generic / Chemical Name',
                                hintText: 'e.g. Paracetamol + Caffeine',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Category Dropdown
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(labelText: 'Category'),
                              items: AppConstants.medicineCategories.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Unit Dropdown
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              decoration: const InputDecoration(labelText: 'Packaging Unit'),
                              items: AppConstants.medicineUnits.map((u) {
                                return DropdownMenuItem(value: u, child: Text(u));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedUnit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _strengthController,
                              decoration: const InputDecoration(
                                labelText: 'Strength / Dosage Spec',
                                hintText: 'e.g. 500mg, 20mg, 100ml',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _manufacturerController,
                              decoration: const InputDecoration(
                                labelText: 'Manufacturer / Brand',
                                hintText: 'e.g. Beximco, Square, Incepta',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Pricing & Stock Inventory
                      const Text(
                        'PRICING & STOCK INVENTORY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Selling Price (৳) *',
                                prefixText: '৳ ',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter price';
                                if (double.tryParse(v) == null) return 'Valid number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _costPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Wholesale / Cost (৳)',
                                prefixText: '৳ ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Current Stock *',
                                hintText: '50',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter stock';
                                if (int.tryParse(v) == null) return 'Integer';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _minAlertController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Low Stock Alert At',
                                hintText: '10',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 3: Medicine Image / Photo (Camera & Storage Upload)
                      const Text(
                        'MEDICINE PHOTO / IMAGE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Thumbnail Preview
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _selectedImageBytes != null
                                  ? Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : (_currentImageUrl != null && _currentImageUrl!.trim().isNotEmpty
                                      ? Image.network(
                                          _currentImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.add_a_photo_rounded,
                                            size: 36,
                                            color: AppColors.primary.withValues(alpha: 0.6),
                                          ),
                                        )),
                            ),
                            const SizedBox(width: 18),
                            // Action Buttons: Camera & Storage
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      // 1. Capture by Camera
                                      ElevatedButton.icon(
                                        onPressed: _captureFromCamera,
                                        icon: const Icon(Icons.photo_camera_rounded, size: 18),
                                        label: const Text('Capture with Camera'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        ),
                                      ),
                                      // 2. Upload from Storage / Gallery
                                      OutlinedButton.icon(
                                        onPressed: _pickFromStorage,
                                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                                        label: const Text('Upload from Storage'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        ),
                                      ),
                                      // 3. Remove photo button (if image present)
                                      if (_selectedImageBytes != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                                        TextButton.icon(
                                          onPressed: _removeSelectedImage,
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                          label: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Take a live photo on mobile devices or select an image file from device storage.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 4: Details & Prescription
                      SwitchListTile(
                        value: _requiresPrescription,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Prescription Required by Doctor', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Require prescription verification before dispensing', style: TextStyle(fontSize: 12)),
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _requiresPrescription = val),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Medical Description / Indications',
                          hintText: 'e.g. Effective relief for headache, fever, migraine...',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _dosageController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Dosage & Administration Instructions',
                          hintText: 'e.g. 1-2 tablets every 4 to 6 hours after meals...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer action buttons
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSaving ? 'Saving...' : (isEditing ? 'Update Medicine' : 'Save to Inventory')),
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
