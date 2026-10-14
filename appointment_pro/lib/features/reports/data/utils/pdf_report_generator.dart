import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../bookings/data/models/booking_model.dart';
import '../../../bussiness_setup/data/models/business_model.dart';
import '../models/customer_record_model.dart';
import '../models/report_period.dart';
import '../models/revenue_analytics_model.dart';
import '../models/service_analytics_model.dart';
import '../models/staff_analytics_model.dart';

/// PDF Report Generator for AppointmentPro.
/// Produces professional, clean vector PDF documents for appointments,
/// customer records, and revenue analytics summary.
class PdfReportGenerator {
  static final _primaryColor = PdfColor.fromInt(0xFF0F172A);
  static final _accentColor = PdfColor.fromInt(0xFF0EA5E9);
  static final _borderColor = PdfColor.fromInt(0xFFCBD5E1);
  static final _headerBgColor = PdfColor.fromInt(0xFFF1F5F9);
  static final _textColor = PdfColor.fromInt(0xFF1E293B);
  static final _secondaryTextColor = PdfColor.fromInt(0xFF64748B);
  static final _successColor = PdfColor.fromInt(0xFF059669);
  static final _errorColor = PdfColor.fromInt(0xFFDC2626);

  static String _formatCurrency(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  /// Sanitizes text to standard ASCII characters to avoid PDF font glyph missing errors
  static String _cleanText(String? input, [String fallback = '-']) {
    if (input == null || input.trim().isEmpty) return fallback;
    return input
        .replaceAll('\u2014', '-') // em-dash
        .replaceAll('\u2013', '-') // en-dash
        .replaceAll('\u2022', '|') // bullet
        .replaceAll('\u2018', "'") // left single quote
        .replaceAll('\u2019', "'") // right single quote
        .replaceAll('\u201C', '"') // left double quote
        .replaceAll('\u201D', '"') // right double quote
        .replaceAll('\u20B9', 'Rs. ') // Rupee sign
        .replaceAll('\u00A0', ' ') // non-breaking space
        .trim();
  }

  /// Loads full Unicode font (Roboto) if available, falling back safely to Helvetica
  static Future<pw.ThemeData> _getPdfTheme() async {
    try {
      final regular = await PdfGoogleFonts.robotoRegular();
      final bold = await PdfGoogleFonts.robotoBold();
      return pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      return pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
    }
  }

  /// Builds a standard document header with business info and generation date
  static pw.Widget _buildHeader({
    required String title,
    required String subtitle,
    BusinessModel? business,
  }) {
    final rawName = business?.name.trim().isNotEmpty == true
        ? business!.name
        : 'AppointmentPro Business';
    final businessName = _cleanText(rawName);

    final businessPhone = business?.phone?.trim().isNotEmpty == true
        ? '${business?.countryCode ?? "+91"} ${business?.phone}'
        : null;
    final businessEmail = business?.email?.trim().isNotEmpty == true
        ? business?.email
        : null;

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 14),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _borderColor, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              if (businessPhone != null || businessEmail != null) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  [businessPhone, businessEmail]
                      .whereType<String>()
                      .map((s) => _cleanText(s))
                      .join(' | '),
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
              pw.SizedBox(height: 6),
              pw.Text(
                _cleanText(title),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              pw.Text(
                _cleanText(subtitle),
                style: pw.TextStyle(
                  fontSize: 9,
                  color: _secondaryTextColor,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _headerBgColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'CONFIDENTIAL REPORT',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Generated on:',
                style: pw.TextStyle(fontSize: 8, color: _secondaryTextColor),
              ),
              pw.Text(
                dateStr,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the standard footer with page numbering
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _borderColor, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'AppointmentPro | Business Management & Analytics',
            style: pw.TextStyle(fontSize: 8, color: _secondaryTextColor),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Generates Appointments PDF Report
  static Future<Uint8List> generateAppointmentsPdf({
    required List<BookingModel> bookings,
    required ReportPeriod period,
    BusinessModel? business,
  }) async {
    final theme = await _getPdfTheme();
    final pdf = pw.Document(theme: theme);

    final totalBookings = bookings.length;
    final completedBookings =
        bookings.where((b) => b.status == BookingStatus.completed).toList();
    final grossRevenue =
        completedBookings.fold(0.0, (sum, b) => sum + b.price);
    final confirmedCount =
        bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final cancelledCount =
        bookings.where((b) => b.status == BookingStatus.cancelled).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title: 'Appointments Report',
          subtitle: 'Period: ${period.label} ($totalBookings records)',
          business: business,
        ),
        footer: _buildFooter,
        build: (context) => [
          // KPI Metric Bar
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              color: _headerBgColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildKpiSummaryItem('Total Appointments', '$totalBookings'),
                _buildKpiSummaryItem('Completed', '${completedBookings.length}'),
                _buildKpiSummaryItem('Confirmed', '$confirmedCount'),
                _buildKpiSummaryItem('Cancelled', '$cancelledCount'),
                _buildKpiSummaryItem('Completed Revenue', _formatCurrency(grossRevenue), isBold: true),
              ],
            ),
          ),

          // Appointments Table
          if (bookings.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 40),
                child: pw.Text(
                  'No appointments recorded for this period in Local Storage.',
                  style: pw.TextStyle(color: _secondaryTextColor, fontSize: 11),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: _borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
              headerDecoration: pw.BoxDecoration(color: _headerBgColor),
              headerHeight: 24,
              cellHeight: 20,
              cellStyle: pw.TextStyle(fontSize: 8, color: _textColor),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.center,
                6: pw.Alignment.centerRight,
              },
              headers: [
                'Date',
                'Time',
                'Customer',
                'Service',
                'Staff',
                'Status',
                'Amount',
              ],
              data: bookings.map((b) {
                final dateFormatted =
                    DateFormat('dd MMM yy').format(b.startAt);
                final timeFormatted =
                    DateFormat('hh:mm a').format(b.startAt);
                final custName = _cleanText(b.customerName, 'Customer');
                final custPhone = _cleanText(b.customerPhone, '');
                final custInfo = custPhone.isNotEmpty
                    ? '$custName\n($custPhone)'
                    : custName;

                return [
                  dateFormatted,
                  timeFormatted,
                  custInfo,
                  _cleanText(b.serviceName, 'Service'),
                  _cleanText(b.staffName, 'Direct'),
                  b.status.displayName,
                  _formatCurrency(b.price),
                ];
              }).toList(),
            ),

          if (bookings.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total Completed Revenue: ',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  _formatCurrency(grossRevenue),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _successColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// 2. Generates Customer Records Directory PDF Report
  static Future<Uint8List> generateCustomerRecordsPdf({
    required List<CustomerRecordModel> customers,
    BusinessModel? business,
  }) async {
    final theme = await _getPdfTheme();
    final pdf = pw.Document(theme: theme);

    final totalCustomers = customers.length;
    final repeatCustomers = customers.where((c) => c.isRepeatCustomer).length;
    final totalSpend =
        customers.fold(0.0, (sum, c) => sum + c.totalSpent);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title: 'Customer Directory & Spending Report',
          subtitle: 'All-Time Client History ($totalCustomers unique clients)',
          business: business,
        ),
        footer: _buildFooter,
        build: (context) => [
          // KPI Metric Bar
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              color: _headerBgColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildKpiSummaryItem('Total Clients', '$totalCustomers'),
                _buildKpiSummaryItem('Repeat Clients', '$repeatCustomers'),
                _buildKpiSummaryItem(
                  'Repeat Rate',
                  totalCustomers > 0
                      ? '${((repeatCustomers / totalCustomers) * 100).toStringAsFixed(0)}%'
                      : '0%',
                ),
                _buildKpiSummaryItem('Total Lifetime Spend', _formatCurrency(totalSpend), isBold: true),
              ],
            ),
          ),

          if (customers.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 40),
                child: pw.Text(
                  'No customer booking history found in Local Storage.',
                  style: pw.TextStyle(color: _secondaryTextColor, fontSize: 11),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: _borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
              headerDecoration: pw.BoxDecoration(color: _headerBgColor),
              headerHeight: 24,
              cellHeight: 20,
              cellStyle: pw.TextStyle(fontSize: 8, color: _textColor),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.centerRight,
                7: pw.Alignment.centerRight,
              },
              headers: [
                'Customer Name',
                'Phone',
                'Email',
                'Visits',
                'Completed',
                'Status',
                'Total Spend',
                'Last Visit',
              ],
              data: customers.map((c) {
                final lastVisitFormatted =
                    DateFormat('dd MMM yy').format(c.lastVisit);
                final statusLabel = c.isRepeatCustomer ? 'Repeat / VIP' : 'New Client';

                return [
                  _cleanText(c.customerName, 'Customer'),
                  _cleanText(c.customerPhone, '-'),
                  _cleanText(c.customerEmail, '-'),
                  '${c.totalBookings}',
                  '${c.completedBookings}',
                  statusLabel,
                  _formatCurrency(c.totalSpent),
                  lastVisitFormatted,
                ];
              }).toList(),
            ),

          if (customers.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Combined Client Lifetime Spend: ',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  _formatCurrency(totalSpend),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _successColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// 3. Generates Revenue & Analytics Summary PDF Report
  static Future<Uint8List> generateRevenueSummaryPdf({
    required RevenueAnalyticsModel analytics,
    required List<ServiceAnalyticsModel> services,
    required List<StaffAnalyticsModel> staff,
    required ReportPeriod period,
    BusinessModel? business,
  }) async {
    final theme = await _getPdfTheme();
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          title: 'Revenue & Financial Analytics Report',
          subtitle: 'Period: ${period.label}',
          business: business,
        ),
        footer: _buildFooter,
        build: (context) => [
          // Financial KPI Matrix
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            margin: const pw.EdgeInsets.only(bottom: 20),
            decoration: pw.BoxDecoration(
              color: _headerBgColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EXECUTIVE FINANCIAL OVERVIEW',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFinancialMetricBox('Gross Revenue', _formatCurrency(analytics.grossRevenue), _successColor),
                    _buildFinancialMetricBox('Projected Upcoming', _formatCurrency(analytics.projectedRevenue), _accentColor),
                    _buildFinancialMetricBox('Lost Revenue', _formatCurrency(analytics.lostRevenue), _errorColor),
                    _buildFinancialMetricBox('Avg Order Value', _formatCurrency(analytics.averageOrderValue), _textColor),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFinancialMetricBox('Completed Bookings', '${analytics.completedCount}', _textColor),
                    _buildFinancialMetricBox('Confirmed Bookings', '${analytics.confirmedCount}', _textColor),
                    _buildFinancialMetricBox('Completion Rate', '${analytics.completionRate.toStringAsFixed(1)}%', _successColor),
                    _buildFinancialMetricBox('Cancellation Rate', '${analytics.cancellationRate.toStringAsFixed(1)}%', _errorColor),
                  ],
                ),
              ],
            ),
          ),

          // Service Analytics Table
          pw.Text(
            'SERVICE PERFORMANCE BREAKDOWN',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 6),
          if (services.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Text(
                'No service booking activity recorded for this period.',
                style: pw.TextStyle(fontSize: 8.5, color: _secondaryTextColor),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: _borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
              headerDecoration: pw.BoxDecoration(color: _headerBgColor),
              headerHeight: 22,
              cellHeight: 18,
              cellStyle: pw.TextStyle(fontSize: 8, color: _textColor),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              headers: ['Service Name', 'Total Bookings', 'Completed', 'Revenue', '% Share of Revenue'],
              data: services.map((s) {
                return [
                  _cleanText(s.serviceName, 'Service'),
                  '${s.totalBookings}',
                  '${s.completedBookings}',
                  _formatCurrency(s.revenue),
                  '${s.shareOfTotalRevenue.toStringAsFixed(1)}%',
                ];
              }).toList(),
            ),

          pw.SizedBox(height: 18),

          // Staff Analytics Table
          if (staff.isNotEmpty) ...[
            pw.Text(
              'TEAM MEMBER PERFORMANCE',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: _borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
              headerDecoration: pw.BoxDecoration(color: _headerBgColor),
              headerHeight: 22,
              cellHeight: 18,
              cellStyle: pw.TextStyle(fontSize: 8, color: _textColor),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              headers: ['Staff Name', 'Assigned', 'Completed', 'Revenue Generated', 'Completion Rate'],
              data: staff.map((st) {
                return [
                  _cleanText(st.staffName, 'Staff'),
                  '${st.totalAppointments}',
                  '${st.completedAppointments}',
                  _formatCurrency(st.revenue),
                  '${st.completionRate.toStringAsFixed(0)}%',
                ];
              }).toList(),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiSummaryItem(String label, String value, {bool isBold = false}) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: isBold ? _successColor : _textColor,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          _cleanText(label),
          style: pw.TextStyle(fontSize: 7.5, color: _secondaryTextColor),
        ),
      ],
    );
  }

  static pw.Widget _buildFinancialMetricBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _cleanText(label),
            style: pw.TextStyle(fontSize: 7.5, color: _secondaryTextColor),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
