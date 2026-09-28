import 'package:uuid/uuid.dart';

class MedicineModel {
  final String id;
  final String name;
  final String genericName;
  final String category;
  final String manufacturer;
  final String strength;
  final String unit;
  final double price;
  final double costPrice;
  final int stockQuantity;
  final int minStockAlert;
  final String? imageUrl;
  final bool requiresPrescription;
  final String description;
  final String dosageInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicineModel({
    String? id,
    required this.name,
    this.genericName = '',
    this.category = 'Tablet',
    this.manufacturer = '',
    this.strength = '',
    this.unit = 'Strip (10 pcs)',
    required this.price,
    this.costPrice = 0.0,
    this.stockQuantity = 0,
    this.minStockAlert = 10,
    this.imageUrl,
    this.requiresPrescription = false,
    this.description = '',
    this.dosageInstructions = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOutOfStock => stockQuantity <= 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= minStockAlert;

  MedicineModel copyWith({
    String? id,
    String? name,
    String? genericName,
    String? category,
    String? manufacturer,
    String? strength,
    String? unit,
    double? price,
    double? costPrice,
    int? stockQuantity,
    int? minStockAlert,
    String? imageUrl,
    bool? requiresPrescription,
    String? description,
    String? dosageInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      strength: strength ?? this.strength,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      imageUrl: imageUrl ?? this.imageUrl,
      requiresPrescription: requiresPrescription ?? this.requiresPrescription,
      description: description ?? this.description,
      dosageInstructions: dosageInstructions ?? this.dosageInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      name: map['name']?.toString() ?? '',
      genericName: map['generic_name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Tablet',
      manufacturer: map['manufacturer']?.toString() ?? '',
      strength: map['strength']?.toString() ?? '',
      unit: map['unit']?.toString() ?? 'Strip',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      minStockAlert: (map['min_stock_alert'] as num?)?.toInt() ?? 10,
      imageUrl: map['image_url']?.toString(),
      requiresPrescription: map['requires_prescription'] == true,
      description: map['description']?.toString() ?? '',
      dosageInstructions: map['dosage_instructions']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'generic_name': genericName,
      'category': category,
      'manufacturer': manufacturer,
      'strength': strength,
      'unit': unit,
      'price': price,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'min_stock_alert': minStockAlert,
      'image_url': imageUrl,
      'requires_prescription': requiresPrescription,
      'description': description,
      'dosage_instructions': dosageInstructions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Initial sample medicines for testing and demo display
  static List<MedicineModel> get sampleMedicines => [
        MedicineModel(
          id: 'med-001',
          name: 'Napa Extra',
          genericName: 'Paracetamol + Caffeine',
          category: 'Tablet',
          manufacturer: 'Beximco Pharmaceuticals',
          strength: '500mg + 65mg',
          unit: 'Strip (10 pcs)',
          price: 35.0,
          costPrice: 28.0,
          stockQuantity: 140,
          minStockAlert: 20,
          imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80',
          requiresPrescription: false,
          description: 'Effective relief for headache, fever, migraine, and body aches.',
          dosageInstructions: '1-2 tablets every 4 to 6 hours as needed. Do not exceed 8 tablets daily.',
        ),
        MedicineModel(
          id: 'med-002',
          name: 'Sergel 20mg',
          genericName: 'Esomeprazole Magnesium',
          category: 'Capsule',
          manufacturer: 'Healthcare Pharmaceuticals',
          strength: '20mg',
          unit: 'Strip (10 pcs)',
          price: 70.0,
          costPrice: 58.0,
          stockQuantity: 85,
          minStockAlert: 15,
          imageUrl: 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400&auto=format&fit=crop&q=80',
          requiresPrescription: false,
          description: 'Proton pump inhibitor for GERD, acid reflux, and gastric ulcers.',
          dosageInstructions: '1 capsule daily before breakfast with plenty of water.',
        ),
        MedicineModel(
          id: 'med-003',
          name: 'Monas 10mg',
          genericName: 'Montelukast Sodium',
          category: 'Tablet',
          manufacturer: 'Acme Laboratories',
          strength: '10mg',
          unit: 'Strip (10 pcs)',
          price: 160.0,
          costPrice: 135.0,
          stockQuantity: 8, // Low stock demo!
          minStockAlert: 15,
          imageUrl: 'https://images.unsplash.com/photo-1550572017-edd951aa8f72?w=400&auto=format&fit=crop&q=80',
          requiresPrescription: true,
          description: 'Leukotriene receptor antagonist for chronic asthma and allergic rhinitis.',
          dosageInstructions: '1 tablet daily at evening bedtime.',
        ),
        MedicineModel(
          id: 'med-004',
          name: 'Tusca Cold & Cough',
          genericName: 'Dextromethorphan + Pseudoephedrine',
          category: 'Syrup',
          manufacturer: 'Square Pharmaceuticals',
          strength: '100ml',
          unit: 'Bottle (100ml)',
          price: 95.0,
          costPrice: 75.0,
          stockQuantity: 42,
          minStockAlert: 10,
          imageUrl: 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=400&auto=format&fit=crop&q=80',
          requiresPrescription: false,
          description: 'Soothing syrup for dry and chesty cough, nasal congestion, and throat irritation.',
          dosageInstructions: '10ml (2 teaspoonfuls) 3 times daily after meals.',
        ),
        MedicineModel(
          id: 'med-005',
          name: 'Seclo 20mg',
          genericName: 'Omeprazole',
          category: 'Capsule',
          manufacturer: 'Square Pharmaceuticals',
          strength: '20mg',
          unit: 'Strip (10 pcs)',
          price: 60.0,
          costPrice: 48.0,
          stockQuantity: 0, // Out of stock demo!
          minStockAlert: 20,
          imageUrl: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400&auto=format&fit=crop&q=80',
          requiresPrescription: false,
          description: 'Relieves acidity, heartburn, and stomach ulcer pain.',
          dosageInstructions: '1 capsule 30 minutes before meal once daily.',
        ),
        MedicineModel(
          id: 'med-006',
          name: 'Bextram Gold Multivitamin',
          genericName: 'Multivitamins & Minerals with Zinc',
          category: 'Vitamins & Supplements',
          manufacturer: 'Beximco Pharmaceuticals',
          strength: '30 Tablets',
          unit: 'Bottle (200ml)',
          price: 320.0,
          costPrice: 260.0,
          stockQuantity: 30,
          minStockAlert: 10,
          imageUrl: 'https://images.unsplash.com/photo-1577401239170-897942555fb3?w=400&auto=format&fit=crop&q=80',
          requiresPrescription: false,
          description: 'Comprehensive daily multivitamin for immunity, energy, and overall health.',
          dosageInstructions: '1 tablet daily after lunch or breakfast.',
        ),
      ];
}
