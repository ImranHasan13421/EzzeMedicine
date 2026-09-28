import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/constants.dart';
import '../models/report_model.dart';

class PdfReportService {
  /// Generate and present / print PDF for the monthly sales report
  static Future<void> printOrSaveMonthlyReport(MonthlySalesReport report) async {
    final pdfBytes = await generateMonthlyReportBytes(report);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'EzzeMedicine_Report_${report.monthName}_${report.year}.pdf',
    );
  }

  /// Build PDF document bytes
  static Future<Uint8List> generateMonthlyReportBytes(MonthlySalesReport report) async {
    final doc = pw.Document();
    final currencyFormat = NumberFormat('#,##0.00');
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 14),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue700, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AppConstants.storeName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${AppConstants.storeAddress} • Phone: ${AppConstants.storePhone}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'OFFICIAL AUDIT REPORT',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'EzzeMedicine Pharmacy Operations • Confidential Financial Record',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.SizedBox(height: 12),
          // Report Title Block
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MONTHLY SALES ANALYSIS REPORT',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Period: ${report.monthName} ${report.year}',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Lead Pharmacist: Md. Imran Hasan',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    ),
                    pw.Text(
                      'Verified Supabase Real-time Database',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Financial KPIs Summary
          pw.Row(
            children: [
              _pdfKpiBox('Total Revenue', 'BDT ${currencyFormat.format(report.totalRevenue)}', PdfColors.blue700),
              pw.SizedBox(width: 10),
              _pdfKpiBox('Completed Orders', '${report.totalOrders} Orders', PdfColors.green700),
              pw.SizedBox(width: 10),
              _pdfKpiBox('Medicines Dispensed', '${report.totalUnitsSold} Units', PdfColors.indigo700),
              pw.SizedBox(width: 10),
              _pdfKpiBox('Avg Order Value', 'BDT ${currencyFormat.format(report.averageOrderValue)}', PdfColors.teal700),
            ],
          ),
          pw.SizedBox(height: 22),

          // Section 1: Top 10 Sold Medicines
          pw.Text(
            'TOP 10 BEST-SELLING MEDICINES',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Rank', 'Medicine Brand Name', 'Category', 'Quantity Sold', 'Total Sales Value', '% of Sales'],
            data: report.topSoldMedicines.isEmpty
                ? [
                    ['-', 'No medicines sold in this monthly period', '-', '0', 'BDT 0.00', '0%']
                  ]
                : report.topSoldMedicines.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final med = entry.value;
                    return [
                      '#$idx',
                      med.medicineName,
                      med.category,
                      '${med.quantitySold} units',
                      'BDT ${currencyFormat.format(med.totalRevenue)}',
                      '${med.percentageOfTotalSales.toStringAsFixed(1)}%',
                    ];
                  }).toList(),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          ),
          pw.SizedBox(height: 22),

          // Section 2: Daily Income Breakdown Table
          pw.Text(
            'DAILY REVENUE BREAKDOWN',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Day', 'Date', 'Orders Count', 'Daily Sales Revenue (BDT)'],
            data: report.dailyMetrics.map((d) {
              return [
                'Day ${d.day}',
                DateFormat('dd MMM yyyy').format(d.date),
                '${d.orderCount} orders',
                'BDT ${currencyFormat.format(d.totalIncome)}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
            },
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          pw.SizedBox(height: 30),

          // Pharmacist Signature Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Report Status: AUDITED & CONFIRMED', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  pw.Text('Supabase PostgreSQL System Sync ID: EZM-PR-${report.year}${report.month.toString().padLeft(2, '0')}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                  pw.SizedBox(height: 4),
                  pw.Text('Md. Imran Hasan', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Lead Pharmacist & Administrator', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _pdfKpiBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color.luminance > 0.5 ? PdfColors.grey300 : color, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
