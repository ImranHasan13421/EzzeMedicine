class DailySalesMetric {
  final int day;
  final DateTime date;
  final double totalIncome;
  final int orderCount;

  const DailySalesMetric({
    required this.day,
    required this.date,
    required this.totalIncome,
    required this.orderCount,
  });
}

class TopSoldMedicine {
  final String medicineId;
  final String medicineName;
  final String category;
  final int quantitySold;
  final double totalRevenue;
  final double percentageOfTotalSales;

  const TopSoldMedicine({
    required this.medicineId,
    required this.medicineName,
    required this.category,
    required this.quantitySold,
    required this.totalRevenue,
    this.percentageOfTotalSales = 0.0,
  });
}

class MonthlySalesReport {
  final int year;
  final int month;
  final double totalRevenue;
  final int totalOrders;
  final int totalUnitsSold;
  final double averageOrderValue;
  final double totalDeliveryCharges;
  final List<DailySalesMetric> dailyMetrics;
  final List<TopSoldMedicine> topSoldMedicines;

  const MonthlySalesReport({
    required this.year,
    required this.month,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalUnitsSold,
    required this.averageOrderValue,
    required this.totalDeliveryCharges,
    required this.dailyMetrics,
    required this.topSoldMedicines,
  });

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Month $month';
  }

  double get maxDailyIncome {
    if (dailyMetrics.isEmpty) return 0.0;
    double max = 0.0;
    for (final m in dailyMetrics) {
      if (m.totalIncome > max) max = m.totalIncome;
    }
    return max;
  }
}
