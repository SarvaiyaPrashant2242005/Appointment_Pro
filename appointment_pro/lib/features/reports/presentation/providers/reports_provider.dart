import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../data/models/customer_record_model.dart';
import '../../data/models/report_period.dart';
import '../../data/models/revenue_analytics_model.dart';
import '../../data/models/service_analytics_model.dart';
import '../../data/models/staff_analytics_model.dart';
import '../../data/repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final bookingRepo = ref.watch(bookingRepositoryProvider);
  final serviceRepo = ref.watch(serviceRepositoryProvider);
  final staffRepo = ref.watch(staffRepositoryProvider);

  return ReportsRepository(
    bookingRepo: bookingRepo,
    serviceRepo: serviceRepo,
    staffRepo: staffRepo,
  );
});

final selectedReportPeriodProvider =
    NotifierProvider<SelectedReportPeriodNotifier, ReportPeriod>(
  SelectedReportPeriodNotifier.new,
);

class SelectedReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.thisMonth;

  void setPeriod(ReportPeriod period) => state = period;
}

final revenueAnalyticsProvider =
    FutureProvider<RevenueAnalyticsModel>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider) ?? '';
  final period = ref.watch(selectedReportPeriodProvider);
  final repo = ref.watch(reportsRepositoryProvider);

  // Recompute when bookings change
  ref.watch(bookingsProvider);

  return repo.computeRevenueAnalytics(businessId, period);
});

final serviceAnalyticsProvider =
    FutureProvider<List<ServiceAnalyticsModel>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider) ?? '';
  final period = ref.watch(selectedReportPeriodProvider);
  final repo = ref.watch(reportsRepositoryProvider);

  ref.watch(bookingsProvider);
  ref.watch(servicesProvider);

  return repo.computeServiceAnalytics(businessId, period);
});

final staffAnalyticsProvider =
    FutureProvider<List<StaffAnalyticsModel>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider) ?? '';
  final period = ref.watch(selectedReportPeriodProvider);
  final repo = ref.watch(reportsRepositoryProvider);

  ref.watch(bookingsProvider);
  ref.watch(staffProvider);

  return repo.computeStaffAnalytics(businessId, period);
});

final customerRecordsProvider =
    FutureProvider<List<CustomerRecordModel>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider) ?? '';
  final repo = ref.watch(reportsRepositoryProvider);
  ref.watch(bookingsProvider);

  return repo.computeCustomerRecords(businessId);
});

final periodBookingsProvider =
    FutureProvider<List<BookingModel>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider) ?? '';
  final period = ref.watch(selectedReportPeriodProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  ref.watch(bookingsProvider);

  return repo.getBookingsForPeriod(businessId, period);
});
