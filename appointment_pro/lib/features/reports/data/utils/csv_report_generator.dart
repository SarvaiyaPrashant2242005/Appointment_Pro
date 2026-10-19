import 'package:intl/intl.dart';

import '../../../bookings/data/models/booking_model.dart';
import '../models/customer_record_model.dart';
import '../models/report_period.dart';
import '../models/revenue_analytics_model.dart';

class CsvReportGenerator {
  CsvReportGenerator._();

  static String _escapeCsv(dynamic value) {
    if (value == null) return '""';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      final replaced = str.replaceAll('"', '""');
      return '"$replaced"';
    }
    return '"$str"';
  }

  /// Generates a standardized CSV document for Appointment Records
  static String generateAppointmentsCsv({
    required List<BookingModel> bookings,
    required String businessName,
    ReportPeriod? period,
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('hh:mm a');
    final nowFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Metadata header
    buffer.writeln('# AppointmentPro - Appointments Report');
    buffer.writeln('# Business: $businessName');
    if (period != null) {
      buffer.writeln('# Period: ${period.label}');
    }
    buffer.writeln('# Generated: ${nowFormat.format(DateTime.now())}');
    buffer.writeln('# Total Records: ${bookings.length}');
    buffer.writeln();

    // CSV Header row
    final headers = [
      'Booking ID',
      'Date',
      'Start Time',
      'End Time',
      'Customer Name',
      'Customer Phone',
      'Customer Email',
      'Service',
      'Staff Assigned',
      'Price',
      'Status',
      'Cancellation Reason',
      'Booked On',
    ];
    buffer.writeln(headers.map(_escapeCsv).join(','));

    // Data rows
    for (final b in bookings) {
      final row = [
        b.id,
        dateFormat.format(b.startAt),
        timeFormat.format(b.startAt),
        timeFormat.format(b.endAt),
        b.customerName,
        b.fullPhoneNumber,
        b.customerEmail ?? '',
        b.serviceName ?? 'General Service',
        b.staffName ?? 'Any Staff',
        b.price.toStringAsFixed(2),
        b.status.displayName,
        b.cancellationReason ?? '',
        dateFormat.format(b.createdAt),
      ];
      buffer.writeln(row.map(_escapeCsv).join(','));
    }

    return buffer.toString();
  }

  /// Generates a standardized CSV document for Customer Records
  static String generateCustomerRecordsCsv({
    required List<CustomerRecordModel> customers,
    required String businessName,
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final nowFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Metadata header
    buffer.writeln('# AppointmentPro - Customer Directory Report');
    buffer.writeln('# Business: $businessName');
    buffer.writeln('# Generated: ${nowFormat.format(DateTime.now())}');
    buffer.writeln('# Total Customers: ${customers.length}');
    buffer.writeln();

    // CSV Header row
    final headers = [
      'Customer Name',
      'Phone Number',
      'Email',
      'Total Bookings',
      'Completed Appointments',
      'Cancelled Appointments',
      'Total Spent (₹)',
      'Average Spend (₹)',
      'First Visit',
      'Last Visit',
      'Repeat Customer',
    ];
    buffer.writeln(headers.map(_escapeCsv).join(','));

    // Data rows
    for (final c in customers) {
      final row = [
        c.customerName,
        c.customerPhone,
        c.customerEmail ?? '',
        c.totalBookings,
        c.completedBookings,
        c.cancelledBookings,
        c.totalSpent.toStringAsFixed(2),
        c.averageSpend.toStringAsFixed(2),
        dateFormat.format(c.firstVisit),
        dateFormat.format(c.lastVisit),
        c.isRepeatCustomer ? 'Yes' : 'No',
      ];
      buffer.writeln(row.map(_escapeCsv).join(','));
    }

    return buffer.toString();
  }

  /// Generates a summary CSV document for Revenue & Service analytics
  static String generateRevenueAnalyticsCsv({
    required RevenueAnalyticsModel analytics,
    required ReportPeriod period,
    required String businessName,
  }) {
    final buffer = StringBuffer();
    final nowFormat = DateFormat('yyyy-MM-dd HH:mm');

    buffer.writeln('# AppointmentPro - Revenue & Performance Summary');
    buffer.writeln('# Business: $businessName');
    buffer.writeln('# Period: ${period.label}');
    buffer.writeln('# Generated: ${nowFormat.format(DateTime.now())}');
    buffer.writeln();

    // Metric rows
    buffer.writeln(['Metric', 'Value'].map(_escapeCsv).join(','));
    buffer.writeln(['Gross Revenue', '₹${analytics.grossRevenue.toStringAsFixed(2)}'].map(_escapeCsv).join(','));
    buffer.writeln(['Projected Revenue', '₹${analytics.projectedRevenue.toStringAsFixed(2)}'].map(_escapeCsv).join(','));
    buffer.writeln(['Lost Revenue (Cancelled/No-Show)', '₹${analytics.lostRevenue.toStringAsFixed(2)}'].map(_escapeCsv).join(','));
    buffer.writeln(['Completed Appointments', analytics.completedCount].map(_escapeCsv).join(','));
    buffer.writeln(['Confirmed Upcoming', analytics.confirmedCount].map(_escapeCsv).join(','));
    buffer.writeln(['Cancelled Appointments', analytics.cancelledCount].map(_escapeCsv).join(','));
    buffer.writeln(['No-Show Appointments', analytics.noShowCount].map(_escapeCsv).join(','));
    buffer.writeln(['Total Bookings', analytics.totalBookings].map(_escapeCsv).join(','));
    buffer.writeln(['Completion Rate', '${analytics.completionRate.toStringAsFixed(1)}%'].map(_escapeCsv).join(','));
    buffer.writeln(['Cancellation Rate', '${analytics.cancellationRate.toStringAsFixed(1)}%'].map(_escapeCsv).join(','));
    buffer.writeln(['Average Order Value', '₹${analytics.averageOrderValue.toStringAsFixed(2)}'].map(_escapeCsv).join(','));
    buffer.writeln();

    // Day-by-day or point-by-point chart breakdown
    if (analytics.chartPoints.isNotEmpty) {
      buffer.writeln('# Revenue Over Time Breakdown');
      buffer.writeln(['Interval', 'Date', 'Revenue (₹)', 'Completed Count'].map(_escapeCsv).join(','));
      final dateFormat = DateFormat('yyyy-MM-dd');
      for (final pt in analytics.chartPoints) {
        buffer.writeln([
          pt.label,
          dateFormat.format(pt.date),
          pt.revenue.toStringAsFixed(2),
          pt.completedCount,
        ].map(_escapeCsv).join(','));
      }
    }

    return buffer.toString();
  }
}
