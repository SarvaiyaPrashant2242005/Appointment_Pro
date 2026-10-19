import 'package:intl/intl.dart';

import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/data/repositories/booking_repository.dart';
import '../../../services/data/repositories/service_repository.dart';
import '../../../staff/data/repositories/staff_repository.dart';
import '../models/customer_record_model.dart';
import '../models/report_period.dart';
import '../models/revenue_analytics_model.dart';
import '../models/service_analytics_model.dart';
import '../models/staff_analytics_model.dart';

class ReportsRepository {
  final BookingRepository bookingRepo;
  final ServiceRepository serviceRepo;
  final StaffRepository staffRepo;

  ReportsRepository({
    required this.bookingRepo,
    required this.serviceRepo,
    required this.staffRepo,
  });

  /// Retrieves filtered bookings for the specified period.
  Future<List<BookingModel>> getBookingsForPeriod(
    String businessId,
    ReportPeriod period,
  ) async {
    final all = await bookingRepo.getBookings(businessId);
    final range = period.getDateRange();

    return all.where((b) => range.contains(b.startAt)).toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  /// Calculates total revenue, completed counts, projected, and time breakdown.
  Future<RevenueAnalyticsModel> computeRevenueAnalytics(
    String businessId,
    ReportPeriod period,
  ) async {
    final periodBookings = await getBookingsForPeriod(businessId, period);

    double grossRevenue = 0.0;
    double projectedRevenue = 0.0;
    double lostRevenue = 0.0;
    int completedCount = 0;
    int confirmedCount = 0;
    int cancelledCount = 0;
    int noShowCount = 0;

    for (final b in periodBookings) {
      switch (b.status) {
        case BookingStatus.completed:
          grossRevenue += b.price;
          completedCount++;
          break;
        case BookingStatus.confirmed:
          projectedRevenue += b.price;
          confirmedCount++;
          break;
        case BookingStatus.cancelled:
          lostRevenue += b.price;
          cancelledCount++;
          break;
        case BookingStatus.noShow:
          lostRevenue += b.price;
          noShowCount++;
          break;
      }
    }

    final totalBookings = periodBookings.length;
    final completionRate = totalBookings > 0
        ? (completedCount / totalBookings) * 100.0
        : 0.0;
    final cancellationRate = totalBookings > 0
        ? (cancelledCount / totalBookings) * 100.0
        : 0.0;
    final averageOrderValue = completedCount > 0
        ? (grossRevenue / completedCount)
        : 0.0;

    final chartPoints = _computeChartPoints(period, periodBookings);

    return RevenueAnalyticsModel(
      grossRevenue: grossRevenue,
      projectedRevenue: projectedRevenue,
      lostRevenue: lostRevenue,
      completedCount: completedCount,
      confirmedCount: confirmedCount,
      cancelledCount: cancelledCount,
      noShowCount: noShowCount,
      totalBookings: totalBookings,
      completionRate: completionRate,
      cancellationRate: cancellationRate,
      averageOrderValue: averageOrderValue,
      chartPoints: chartPoints,
    );
  }

  /// Generates grouped chart points according to period
  List<RevenueChartPoint> _computeChartPoints(
    ReportPeriod period,
    List<BookingModel> bookings,
  ) {
    final now = DateTime.now();

    if (period == ReportPeriod.thisWeek) {
      // 7 days Mon - Sun
      final weekday = now.weekday;
      final monday = DateTime(now.year, now.month, now.day - (weekday - 1));
      final points = <RevenueChartPoint>[];

      for (int i = 0; i < 7; i++) {
        final day = DateTime(monday.year, monday.month, monday.day + i);
        final label = DateFormat('EEE').format(day);

        final dayBookings = bookings.where((b) =>
            b.startAt.year == day.year &&
            b.startAt.month == day.month &&
            b.startAt.day == day.day &&
            b.status == BookingStatus.completed);

        final dayRevenue = dayBookings.fold(0.0, (sum, b) => sum + b.price);
        points.add(RevenueChartPoint(
          label: label,
          date: day,
          revenue: dayRevenue,
          completedCount: dayBookings.length,
        ));
      }
      return points;
    }

    if (period == ReportPeriod.thisMonth) {
      // Group by weeks or 5-day intervals
      final points = <RevenueChartPoint>[];
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      for (int dayNum = 1; dayNum <= daysInMonth; dayNum += 4) {
        final day = DateTime(now.year, now.month, dayNum);
        final nextInterval = DateTime(now.year, now.month, (dayNum + 3).clamp(1, daysInMonth), 23, 59, 59);

        final intervalBookings = bookings.where((b) =>
            (b.startAt.isAfter(day) || b.startAt.isAtSameMomentAs(day)) &&
            (b.startAt.isBefore(nextInterval) || b.startAt.isAtSameMomentAs(nextInterval)) &&
            b.status == BookingStatus.completed);

        final revenue = intervalBookings.fold(0.0, (sum, b) => sum + b.price);
        points.add(RevenueChartPoint(
          label: '$dayNum-${nextInterval.day}',
          date: day,
          revenue: revenue,
          completedCount: intervalBookings.length,
        ));
      }
      return points;
    }

    if (period == ReportPeriod.thisYear) {
      // 12 months
      final points = <RevenueChartPoint>[];
      for (int m = 1; m <= 12; m++) {
        final monthDate = DateTime(now.year, m, 1);
        final label = DateFormat('MMM').format(monthDate);

        final monthBookings = bookings.where((b) =>
            b.startAt.year == now.year &&
            b.startAt.month == m &&
            b.status == BookingStatus.completed);

        final revenue = monthBookings.fold(0.0, (sum, b) => sum + b.price);
        points.add(RevenueChartPoint(
          label: label,
          date: monthDate,
          revenue: revenue,
          completedCount: monthBookings.length,
        ));
      }
      return points;
    }

    // Default (Today / All Time): list chronological or day points
    final Map<String, List<BookingModel>> grouped = {};
    final dateFormat = DateFormat('MMM d');

    for (final b in bookings.where((b) => b.status == BookingStatus.completed)) {
      final key = dateFormat.format(b.startAt);
      grouped.putIfAbsent(key, () => []).add(b);
    }

    if (grouped.isEmpty) {
      return [
        RevenueChartPoint(
          label: DateFormat('MMM d').format(now),
          date: now,
          revenue: 0.0,
          completedCount: 0,
        ),
      ];
    }

    return grouped.entries.map((e) {
      final rev = e.value.fold(0.0, (sum, b) => sum + b.price);
      return RevenueChartPoint(
        label: e.key,
        date: e.value.first.startAt,
        revenue: rev,
        completedCount: e.value.length,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Computes service-by-service revenue and booking volume.
  Future<List<ServiceAnalyticsModel>> computeServiceAnalytics(
    String businessId,
    ReportPeriod period,
  ) async {
    final periodBookings = await getBookingsForPeriod(businessId, period);
    final allServices = await serviceRepo.getServices(businessId);
    final knownServices = {for (final s in allServices) s.id: s};

    final totalCompletedRevenue = periodBookings
        .where((b) => b.status == BookingStatus.completed)
        .fold(0.0, (sum, b) => sum + b.price);

    final serviceIds = <String>{
      ...allServices.map((s) => s.id),
      ...periodBookings.map((b) => b.serviceId),
    };

    final analytics = <ServiceAnalyticsModel>[];

    for (final srvId in serviceIds) {
      if (srvId.trim().isEmpty) continue;
      final srv = knownServices[srvId];
      final serviceBookings =
          periodBookings.where((b) => b.serviceId == srvId).toList();
      final completedBookings = serviceBookings
          .where((b) => b.status == BookingStatus.completed)
          .toList();

      final revenue = completedBookings.fold(0.0, (sum, b) => sum + b.price);
      final share = totalCompletedRevenue > 0
          ? (revenue / totalCompletedRevenue) * 100.0
          : 0.0;
      final avgPrice = completedBookings.isNotEmpty
          ? (revenue / completedBookings.length)
          : (srv?.price ?? 0.0);

      final serviceName = srv?.name ??
          serviceBookings
              .map((b) => b.serviceName)
              .firstWhere((name) => name != null && name.trim().isNotEmpty,
                  orElse: () => null) ??
          'Service ($srvId)';

      analytics.add(ServiceAnalyticsModel(
        serviceId: srvId,
        serviceName: serviceName,
        totalBookings: serviceBookings.length,
        completedBookings: completedBookings.length,
        revenue: revenue,
        shareOfTotalRevenue: share,
        averagePrice: avgPrice,
      ));
    }

    // Sort by revenue descending, then by booking count
    analytics.sort((a, b) {
      final revCompare = b.revenue.compareTo(a.revenue);
      if (revCompare != 0) return revCompare;
      return b.totalBookings.compareTo(a.totalBookings);
    });

    return analytics;
  }

  /// Computes staff member performance and completed appointments.
  Future<List<StaffAnalyticsModel>> computeStaffAnalytics(
    String businessId,
    ReportPeriod period,
  ) async {
    final periodBookings = await getBookingsForPeriod(businessId, period);
    final allStaff = await staffRepo.getStaff(businessId);
    final knownStaff = {for (final s in allStaff) s.id: s};

    final staffIds = <String>{
      ...allStaff.map((s) => s.id),
      ...periodBookings
          .where((b) => b.staffId != null && b.staffId!.trim().isNotEmpty)
          .map((b) => b.staffId!),
    };

    final analytics = <StaffAnalyticsModel>[];

    for (final stId in staffIds) {
      final staff = knownStaff[stId];
      final staffBookings =
          periodBookings.where((b) => b.staffId == stId).toList();
      final completed = staffBookings
          .where((b) => b.status == BookingStatus.completed)
          .toList();
      final revenue = completed.fold(0.0, (sum, b) => sum + b.price);
      final rate = staffBookings.isNotEmpty
          ? (completed.length / staffBookings.length) * 100.0
          : 0.0;

      final staffName = staff?.name ??
          staffBookings
              .map((b) => b.staffName)
              .firstWhere((n) => n != null && n.trim().isNotEmpty,
                  orElse: () => null) ??
          'Team Member ($stId)';

      analytics.add(StaffAnalyticsModel(
        staffId: stId,
        staffName: staffName,
        totalAppointments: staffBookings.length,
        completedAppointments: completed.length,
        revenue: revenue,
        completionRate: rate,
      ));
    }

    // Include unassigned if there are bookings with no staff assigned
    final unassigned = periodBookings
        .where((b) => b.staffId == null || b.staffId!.trim().isEmpty)
        .toList();
    if (unassigned.isNotEmpty && allStaff.isNotEmpty) {
      final completed = unassigned
          .where((b) => b.status == BookingStatus.completed)
          .toList();
      final revenue = completed.fold(0.0, (sum, b) => sum + b.price);
      analytics.add(StaffAnalyticsModel(
        staffId: 'unassigned',
        staffName: 'Direct / Unassigned',
        totalAppointments: unassigned.length,
        completedAppointments: completed.length,
        revenue: revenue,
        completionRate: (completed.length / unassigned.length) * 100.0,
      ));
    }

    analytics.sort((a, b) =>
        b.completedAppointments.compareTo(a.completedAppointments));
    return analytics;
  }

  /// Aggregates customer profiles and spending records across all bookings.
  Future<List<CustomerRecordModel>> computeCustomerRecords(
    String businessId,
  ) async {
    final allBookings = await bookingRepo.getBookings(businessId);

    // Group bookings by phone number, or fallback to name
    final Map<String, List<BookingModel>> customerGroups = {};

    for (final b in allBookings) {
      final key = b.customerPhone.trim().isNotEmpty
          ? b.customerPhone.trim()
          : b.customerName.trim().toLowerCase();
      if (key.isNotEmpty) {
        customerGroups.putIfAbsent(key, () => []).add(b);
      }
    }

    final records = <CustomerRecordModel>[];

    for (final group in customerGroups.values) {
      if (group.isEmpty) continue;

      // Sort by startAt ascending
      group.sort((a, b) => a.startAt.compareTo(b.startAt));

      final firstVisit = group.first.startAt;
      final lastVisit = group.last.startAt;
      final customerName = group.last.customerName;
      final customerPhone = group.last.customerPhone;
      final customerEmail = group.where((b) => b.customerEmail != null && b.customerEmail!.isNotEmpty).map((b) => b.customerEmail).firstOrNull;

      final totalBookings = group.length;
      final completedBookings =
          group.where((b) => b.status == BookingStatus.completed).length;
      final cancelledBookings =
          group.where((b) => b.status == BookingStatus.cancelled).length;
      final totalSpent = group
          .where((b) => b.status == BookingStatus.completed)
          .fold(0.0, (sum, b) => sum + b.price);

      records.add(CustomerRecordModel(
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        totalBookings: totalBookings,
        completedBookings: completedBookings,
        cancelledBookings: cancelledBookings,
        totalSpent: totalSpent,
        firstVisit: firstVisit,
        lastVisit: lastVisit,
      ));
    }

    // Sort by total spent descending, then total bookings
    records.sort((a, b) {
      final spentCompare = b.totalSpent.compareTo(a.totalSpent);
      if (spentCompare != 0) return spentCompare;
      return b.totalBookings.compareTo(a.totalBookings);
    });

    return records;
  }
}
