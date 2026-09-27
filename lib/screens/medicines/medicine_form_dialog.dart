import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _dosageController;

  late String _selectedCategory;
  late String _selectedUnit;
  late bool _requiresPrescription;
  bool _isSaving = false;

  // Preset medical images for quick selection
  static const List<Map<String, String>> _presetImages = [
    {
      'label': 'Blister Tablets',
      'url': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80'
    },
    {
      'label': 'Capsules Bottle',
      'url': 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400&auto=format&fit=crop&q=80'
    },
    {
      'label': 'Syrup / Liquid',
      'url': 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=400&auto=format&fit=crop&q=80'
    },
    {
      'label': 'Vitamins / Jar',
      'url': 'https://images.unsplash.com/photo-1577401239170-897942555fb3?w=400&auto=format&fit=crop&q=80'
    },
    {
      'label': 'Strip Pack',
      'url': 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400&auto=format&fit=crop&q=80'
    },
  ];

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
    _imageUrlController = TextEditingController(text: m?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _dosageController = TextEditingController(text: m?.dosageInstructions ?? '');

    _selectedCategory = m?.category ?? AppConstants.medicineCategories.first;
    _selectedUnit = m?.unit ?? AppConstants.medicineUnits.first;
    _requiresPrescription = m?.requiresPrescription ?? false;
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
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickLocalImage() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.xFile.readAsBytes();
        if (!mounted) return;
        final medProvider = context.read<MedicineProvider>();
        final uploadedUrl = await medProvider.uploadImage(bytes, file.name);
        if (uploadedUrl != null) {
          setState(() {
            _imageUrlController.text = uploadedUrl;
          });
        } else {
          // In local mock mode, use a high quality placeholder preset
          setState(() {
            _imageUrlController.text = _presetImages.first['url']!;
          });
        }
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final medProvider = context.read<MedicineProvider>();

    final price = double.tryParse(_priceController.text) ?? 0.0;
    final costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final minAlert = int.tryParse(_minAlertController.text) ?? 10;

    final image = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : _presetImages.first['url'];

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
        imageUrl: image,
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
        imageUrl: image,
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

                      // Section 3: Medicine Image & Photo
                      const Text(
                        'MEDICINE IMAGE / PHOTO',
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
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Thumbnail Preview
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCard : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                    image: _imageUrlController.text.trim().isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(_imageUrlController.text.trim()),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _imageUrlController.text.trim().isEmpty
                                      ? const Icon(Icons.medication_rounded, size: 36, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _pickLocalImage,
                                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                                        label: const Text('Upload Image File (Device/PC)'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Supports JPG, PNG, WebP (Uploaded to Supabase Storage or saved locally)',
                                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Image Web URL or Storage Path',
                                hintText: 'https://...',
                                prefixIcon: Icon(Icons.link_rounded),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),
                            // Quick Presets
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                const Text('Quick Presets: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ..._presetImages.map((preset) {
                                  return ActionChip(
                                    label: Text(preset['label']!, style: const TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      setState(() {
                                        _imageUrlController.text = preset['url']!;
                                      });
                                    },
                                  );
                                }),
                              ],
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
