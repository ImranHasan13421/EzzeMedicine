import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/report_model.dart';
import '../../providers/order_provider.dart';
import '../../services/pdf_report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  int? _hoveredDay;
  bool _isGeneratingPdf = false;

  final List<int> _years = [2024, 2025, 2026, 2027, 2028];
  final List<String> _months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  Future<void> _exportPdf(MonthlySalesReport report) async {
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfReportService.printOrSaveMonthlyReport(report);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderProvider = context.watch<OrderProvider>();
    final report = orderProvider.getMonthlyReport(_selectedYear, _selectedMonth);
    final currencyFormat = NumberFormat('#,##0.00');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => orderProvider.refreshOrders(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title & Controls
              _buildHeader(isDark, report),
              const SizedBox(height: 20),

              // KPI Metric Cards
              _buildKpiGrid(isDark, report, currencyFormat),
              const SizedBox(height: 24),

              // Daily Income Bar Chart
              _buildDailyIncomeChart(isDark, report, currencyFormat),
              const SizedBox(height: 24),

              // Top 10 Best-Selling Medicines
              _buildTopMedicinesSection(isDark, report, currencyFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, MonthlySalesReport report) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.analytics_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sales & Performance Analysis',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monthly financial reports, everyday income bar charts, and top-selling pharmaceuticals',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Controls Bar: Month Selector, Year Selector, Refresh, PDF Generator
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Selectors
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Report Period:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      // Month Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedMonth,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text(
                                  _months[index],
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedMonth = val);
                            },
                          ),
                        ),
                      ),
                      // Year Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedYear,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                            items: _years.map((y) {
                              return DropdownMenuItem(
                                value: y,
                                child: Text(
                                  '$y',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedYear = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Actions: Refresh & PDF Generator
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => context.read<OrderProvider>().refreshOrders(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Refresh'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isGeneratingPdf ? null : () => _exportPdf(report),
                        icon: _isGeneratingPdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: Text(_isGeneratingPdf ? 'Generating...' : 'Export PDF Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiGrid(bool isDark, MonthlySalesReport report, NumberFormat format) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 550
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 2.2,
          children: [
            _kpiCard(
              title: 'TOTAL MONTHLY INCOME',
              value: '৳${format.format(report.totalRevenue)}',
              subtitle: '${report.monthName} $_selectedYear',
              icon: Icons.payments_rounded,
              color: AppColors.primary,
              isDark: isDark,
            ),
            _kpiCard(
              title: 'COMPLETED ORDERS',
              value: '${report.totalOrders}',
              subtitle: 'Delivered & Confirmed',
              icon: Icons.assignment_turned_in_rounded,
              color: AppColors.confirmed,
              isDark: isDark,
            ),
            _kpiCard(
              title: 'MEDICINES DISPENSED',
              value: '${report.totalUnitsSold} Units',
              subtitle: 'Across all catalog categories',
              icon: Icons.medication_rounded,
              color: AppColors.accent,
              isDark: isDark,
            ),
            _kpiCard(
              title: 'AVERAGE ORDER VALUE',
              value: '৳${format.format(report.averageOrderValue)}',
              subtitle: 'Revenue per completed order',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF0284C7),
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyIncomeChart(bool isDark, MonthlySalesReport report, NumberFormat format) {
    final maxIncome = report.maxDailyIncome > 0 ? report.maxDailyIncome : 1000.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY INCOME OVERVIEW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Day-by-day revenue for ${report.monthName} ${report.year}',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                  ),
                ],
              ),
              if (_hoveredDay != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Day $_hoveredDay: ৳${format.format(report.dailyMetrics[_hoveredDay! - 1].totalIncome)} (${report.dailyMetrics[_hoveredDay! - 1].orderCount} orders)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Scrollable Bar Chart
          SizedBox(
            height: 220,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = ((constraints.maxWidth - (report.dailyMetrics.length * 4)) / report.dailyMetrics.length)
                    .clamp(14.0, 36.0);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: report.dailyMetrics.map((metric) {
                      final heightFraction = (metric.totalIncome / maxIncome).clamp(0.04, 1.0);
                      final isHovered = _hoveredDay == metric.day;
                      final isToday = DateTime.now().year == report.year &&
                          DateTime.now().month == report.month &&
                          DateTime.now().day == metric.day;

                      return InkWell(
                        onTap: () => setState(() => _hoveredDay = metric.day),
                        onHover: (hovering) {
                          setState(() => _hoveredDay = hovering ? metric.day : null);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Value label above bar if income > 0
                              if (metric.totalIncome > 0 && isHovered)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '৳${metric.totalIncome.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),

                              // Animated Bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: barWidth,
                                height: 160 * heightFraction,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: metric.totalIncome > 0
                                        ? [
                                            isHovered ? AppColors.accent : AppColors.primary,
                                            AppColors.primaryDark,
                                          ]
                                        : [
                                            isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                                            isDark ? const Color(0xFF1A202C) : const Color(0xFFCBD5E1),
                                          ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  boxShadow: metric.totalIncome > 0 && isHovered
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, -2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Day label
                              Container(
                                padding: isToday
                                    ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                                    : null,
                                decoration: isToday
                                    ? BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      )
                                    : null,
                                child: Text(
                                  '${metric.day}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isToday || isHovered ? FontWeight.w800 : FontWeight.w500,
                                    color: isToday
                                        ? Colors.white
                                        : (isDark ? Colors.white60 : Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day 1',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Daily Sales', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                  const SizedBox(width: 14),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('No Sales Recorded', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                ],
              ),
              Text(
                'Day ${report.dailyMetrics.length}',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopMedicinesSection(bool isDark, MonthlySalesReport report, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOP 10 BEST-SELLING MEDICINES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Highest quantity and revenue generator pharmaceuticals this month',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${report.topSoldMedicines.length} Products Ranked',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (report.topSoldMedicines.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No completed orders recorded in this month',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confirm and deliver incoming orders to generate sales analytics.',
                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.topSoldMedicines.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final med = report.topSoldMedicines[index];
                final rank = index + 1;

                Color rankColor = AppColors.primary;
                if (rank == 1) rankColor = const Color(0xFFD97706); // Gold
                if (rank == 2) rankColor = const Color(0xFF64748B); // Silver
                if (rank == 3) rankColor = const Color(0xFFB45309); // Bronze

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: rankColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Medicine Name & Category
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.medicineName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              med.category,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity Sold
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${med.quantitySold} units',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Quantity Dispensed',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),

                      // Total Sold Price
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '৳${format.format(med.totalRevenue)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${med.percentageOfTotalSales.toStringAsFixed(1)}% of sales',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
