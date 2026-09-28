class AdminUser {
  final String id;
  final String email;
  final String fullName;
  final String storeName;
  final String role;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.storeName = 'EzzeMedicine Pharmacy & Healthcare',
    this.role = 'admin',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'Admin User',
      storeName: map['store_name']?.toString() ?? 'EzzeMedicine Pharmacy',
      role: map['role']?.toString() ?? 'admin',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'store_name': storeName,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
