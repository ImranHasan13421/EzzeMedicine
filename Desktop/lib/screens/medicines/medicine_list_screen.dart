import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import 'medicine_form_dialog.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final _searchController = TextEditingController();
  bool _isTableView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, MedicineModel med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to remove "${med.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MedicineProvider>().deleteMedicine(med.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${med.name}" removed from inventory'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medProvider = context.watch<MedicineProvider>();
    final medicines = medProvider.filteredMedicines;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title, Search & Add button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medicine Inventory',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage pharmacy catalog, stock levels, wholesale prices, and images',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Refresh & Add medicine buttons
                FilledButton.tonalIcon(
                  onPressed: () => context.read<MedicineProvider>().refreshMedicines(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => MedicineFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Medicine'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metrics & Status row
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _metricBadge(
                  label: 'Total Items',
                  count: medProvider.totalCount.toString(),
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                _metricBadge(
                  label: 'Low Stock Alerts',
                  count: medProvider.lowStockCount.toString(),
                  color: AppColors.lowStock,
                  isDark: isDark,
                  alert: medProvider.lowStockCount > 0,
                ),
                _metricBadge(
                  label: 'Out of Stock',
                  count: medProvider.outOfStockCount.toString(),
                  color: AppColors.outOfStock,
                  isDark: isDark,
                  alert: medProvider.outOfStockCount > 0,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & View Toggle
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search medicines by brand, generic name, manufacturer...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                medProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => medProvider.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 12),
                // View toggle (Grid / Table)
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.grid_view_rounded)),
                    ButtonSegment(value: true, icon: Icon(Icons.table_rows_rounded)),
                  ],
                  selected: {_isTableView},
                  onSelectionChanged: (set) => setState(() => _isTableView = set.first),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category filter chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryChip(label: 'All', isSelected: medProvider.selectedCategory == null || medProvider.selectedCategory == 'All'),
                  ...AppConstants.medicineCategories.map((cat) {
                    return _categoryChip(
                      label: cat,
                      isSelected: medProvider.selectedCategory == cat,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medicines List Content
            Expanded(
              child: medProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : medicines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medication_liquid_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No medicines found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Try clearing filters or add a new medicine.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : _isTableView
                          ? _buildTableView(medicines, isDark)
                          : _buildGridView(medicines, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBadge({
    required String label,
    required String count,
    required Color color,
    required bool isDark,
    bool alert = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: alert ? color : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: alert ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count,
              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _categoryChip({required String label, required bool isSelected}) {
    final medProvider = context.read<MedicineProvider>();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        onSelected: (_) {
          medProvider.setSelectedCategory(label == 'All' ? null : label);
        },
      ),
    );
  }

  Widget _buildGridView(List<MedicineModel> medicines, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1300
            ? 4
            : constraints.maxWidth > 950
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;

        final aspectRatio = constraints.maxWidth > 1300
            ? 0.58
            : constraints.maxWidth > 600
                ? 0.60
                : 0.70;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            final med = medicines[index];
            return _buildMedicineCard(med, isDark);
          },
        );
      },
    );
  }

  Widget _buildMedicineCard(MedicineModel med, bool isDark) {
    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        onTap: () => _showMedicineDetails(context, med, isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image banner & Category badge
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                    image: med.imageUrl != null && med.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(med.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: med.imageUrl == null || med.imageUrl!.isEmpty
                      ? const Icon(Icons.medication_rounded, size: 48, color: Colors.grey)
                      : null,
                ),
                // Category chip
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      med.category,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                // Prescription required badge
                if (med.requiresPrescription)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Rx Only',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),

            // Medicine content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    med.genericName.isNotEmpty ? med.genericName : med.strength,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                  if (med.manufacturer.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      med.manufacturer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Medical Description Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0), width: 0.8),
                    ),
                    child: Text(
                      med.description.isNotEmpty
                          ? med.description
                          : (med.dosageInstructions.isNotEmpty
                              ? 'Dosage: ${med.dosageInstructions}'
                              : 'No description available'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price and Unit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '৳${med.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        med.unit,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stock status & Quick adjustment
                  Row(
                    children: [
                      _stockIndicator(med),
                      const Spacer(),
                      // Quick minus button
                      InkWell(
                        onTap: () => context.read<MedicineProvider>().adjustStock(med.id, -1),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.remove, size: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${med.stockQuantity}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      // Quick plus button
                      InkWell(
                        onTap: () => context.read<MedicineProvider>().adjustStock(med.id, 1),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.add, size: 14, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Action Buttons (Info, Edit, Delete)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                        tooltip: 'View Full Description & Details',
                        onPressed: () => _showMedicineDetails(context, med, isDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit Details',
                        onPressed: () => MedicineFormDialog.show(context, medicine: med),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, med),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockIndicator(MedicineModel med) {
    if (med.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.outOfStock.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Out of Stock', style: TextStyle(color: AppColors.outOfStock, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    } else if (med.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.lowStock.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('Low: ${med.stockQuantity}', style: const TextStyle(color: AppColors.lowStock, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.confirmed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('${med.stockQuantity} in stock', style: const TextStyle(color: AppColors.confirmed, fontSize: 11, fontWeight: FontWeight.w600)),
      );
    }
  }

  Widget _buildTableView(List<MedicineModel> medicines, bool isDark) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Generic', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Manufacturer', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
            rows: medicines.map((med) {
              return DataRow(
                cells: [
                  DataCell(
                    InkWell(
                      onTap: () => _showMedicineDetails(context, med, isDark),
                      child: Row(
                        children: [
                          const Icon(Icons.medication_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(med.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(med.genericName.isNotEmpty ? med.genericName : med.strength)),
                  DataCell(Text(med.manufacturer.isNotEmpty ? med.manufacturer : '-')),
                  DataCell(Text(med.category)),
                  DataCell(Text(med.unit)),
                  DataCell(Text('৳${med.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
                  DataCell(
                    Row(
                      children: [
                        _stockIndicator(med),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 16),
                          tooltip: 'Decrease 1',
                          onPressed: () => context.read<MedicineProvider>().adjustStock(med.id, -1),
                        ),
                        Text('${med.stockQuantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          tooltip: 'Increase 1',
                          onPressed: () => context.read<MedicineProvider>().adjustStock(med.id, 1),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        med.description.isNotEmpty
                            ? med.description
                            : (med.dosageInstructions.isNotEmpty ? med.dosageInstructions : '-'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                          tooltip: 'View Full Description & Specs',
                          onPressed: () => _showMedicineDetails(context, med, isDark),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Details',
                          onPressed: () => MedicineFormDialog.show(context, medicine: med),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(context, med),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showMedicineDetails(BuildContext context, MedicineModel med, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                          Text(
                            '${med.category} • ${med.strength.isNotEmpty ? med.strength : med.unit}',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image & Quick Specs
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (med.imageUrl != null && med.imageUrl!.isNotEmpty)
                            Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(right: 18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                                image: DecorationImage(
                                  image: NetworkImage(med.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailItem('Generic Name', med.genericName.isNotEmpty ? med.genericName : 'Not specified', isDark),
                                const SizedBox(height: 8),
                                _detailItem('Manufacturer / Brand', med.manufacturer.isNotEmpty ? med.manufacturer : 'Ezze Healthcare', isDark),
                                const SizedBox(height: 8),
                                _detailItem('Packaging Unit', med.unit, isDark),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _detailItem('Retail Price', '৳${med.price.toStringAsFixed(2)}', isDark, isHighlight: true),
                                    const SizedBox(width: 24),
                                    _detailItem('Wholesale Cost', '৳${med.costPrice.toStringAsFixed(2)}', isDark),
                                    const SizedBox(width: 24),
                                    _detailItem('Stock Level', '${med.stockQuantity} pcs', isDark),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Medical Description / Indications Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'MEDICAL DESCRIPTION & INDICATIONS',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              med.description.isNotEmpty
                                  ? med.description
                                  : 'No specific medical description entered. Click "Edit Details" below to provide indications.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Dosage & Administration Instructions Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.alarm_on_rounded, size: 18, color: AppColors.secondary),
                                SizedBox(width: 8),
                                Text(
                                  'DOSAGE & ADMINISTRATION INSTRUCTIONS',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.secondary, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              med.dosageInstructions.isNotEmpty
                                  ? med.dosageInstructions
                                  : 'Standard clinical dosage guidelines apply. Administer as prescribed by physician.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        MedicineFormDialog.show(context, medicine: med);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Medicine Details'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.grey.shade500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primary : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
