import 'package:appointment_pro/app/theme/app_theme.dart';
import 'package:appointment_pro/app/theme/theme_provider.dart';
import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/bookings/data/datasources/booking_local_datasource.dart';
import 'package:appointment_pro/features/bookings/data/models/booking_model.dart';
import 'package:appointment_pro/features/bookings/data/repositories/booking_repository.dart';
import 'package:appointment_pro/features/bussiness_setup/data/models/business_model.dart';
import 'package:appointment_pro/features/bussiness_setup/presentation/providers/business_provider.dart';
import 'package:appointment_pro/features/reports/data/models/customer_record_model.dart';
import 'package:appointment_pro/features/reports/data/models/report_period.dart';
import 'package:appointment_pro/features/reports/data/repositories/reports_repository.dart';
import 'package:appointment_pro/features/reports/data/utils/csv_report_generator.dart';
import 'package:appointment_pro/features/reports/data/utils/pdf_report_generator.dart';
import 'package:appointment_pro/features/reports/presentation/screens/reports_analytics_screen.dart';
import 'package:appointment_pro/features/reports/presentation/widgets/analytics_kpi_card.dart';
import 'package:appointment_pro/features/reports/presentation/widgets/revenue_bar_chart.dart';
import 'package:appointment_pro/features/services/data/models/service_model.dart';
import 'package:appointment_pro/features/services/data/repositories/service_repository.dart';
import 'package:appointment_pro/features/staff/data/models/staff_model.dart';
import 'package:appointment_pro/features/staff/data/repositories/staff_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorageService storage;
  late BookingRepository bookingRepo;
  late ServiceRepository serviceRepo;
  late StaffRepository staffRepo;
  late ReportsRepository reportsRepo;

  final testBusiness = BusinessModel(
    id: 'biz_metro',
    name: 'Metro Spa & Salon',
    type: 'Spa & Salon',
    createdAt: DateTime(2026, 1, 1),
    isActive: true,
  );

  final service1 = ServiceModel(
    id: 'srv_1',
    businessId: 'biz_metro',
    name: 'Full Body Massage',
    price: 100.0,
    durationMinutes: 60,
  );

  final service2 = ServiceModel(
    id: 'srv_2',
    businessId: 'biz_metro',
    name: 'Express Haircut',
    price: 40.0,
    durationMinutes: 30,
  );

  final staff1 = StaffModel(
    id: 'stf_1',
    businessId: 'biz_metro',
    name: 'David Miller',
    assignedServiceIds: ['srv_1'],
  );

  final staff2 = StaffModel(
    id: 'stf_2',
    businessId: 'biz_metro',
    name: 'Chloe Bennett',
    assignedServiceIds: ['srv_2'],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(prefs);

    bookingRepo = BookingRepository(BookingLocalDataSource(storage));
    serviceRepo = ServiceRepository(storage);
    staffRepo = StaffRepository(storage);

    reportsRepo = ReportsRepository(
      bookingRepo: bookingRepo,
      serviceRepo: serviceRepo,
      staffRepo: staffRepo,
    );

    // Seed Services and Staff
    await serviceRepo.createService(service1);
    await serviceRepo.createService(service2);
    await staffRepo.createStaff(staff1);
    await staffRepo.createStaff(staff2);
  });

  group('ReportsRepository Analytics Computation Tests', () {
    test('Calculates gross revenue, completed counts, and average order value', () async {
      final now = DateTime.now();

      // Booking 1: Completed ($100)
      await bookingRepo.createBooking(BookingModel(
        id: 'bk_1',
        businessId: 'biz_metro',
        serviceId: 'srv_1',
        serviceName: 'Full Body Massage',
        staffId: 'stf_1',
        staffName: 'David Miller',
        customerName: 'Alice Walker',
        customerPhone: '1112223333',
        startAt: now,
        endAt: now.add(const Duration(minutes: 60)),
        price: 100.0,
        status: BookingStatus.completed,
      ));

      // Booking 2: Completed ($40)
      await bookingRepo.createBooking(BookingModel(
        id: 'bk_2',
        businessId: 'biz_metro',
        serviceId: 'srv_2',
        serviceName: 'Express Haircut',
        staffId: 'stf_2',
        staffName: 'Chloe Bennett',
        customerName: 'Bob Vance',
        customerPhone: '4445556666',
        startAt: now,
        endAt: now.add(const Duration(minutes: 30)),
        price: 40.0,
        status: BookingStatus.completed,
      ));

      // Booking 3: Confirmed / Projected ($100)
      await bookingRepo.createBooking(BookingModel(
        id: 'bk_3',
        businessId: 'biz_metro',
        serviceId: 'srv_1',
        serviceName: 'Full Body Massage',
        staffId: 'stf_1',
        staffName: 'David Miller',
        customerName: 'Charlie Day',
        customerPhone: '7778889999',
        startAt: now.add(const Duration(hours: 2)),
        endAt: now.add(const Duration(hours: 3)),
        price: 100.0,
        status: BookingStatus.confirmed,
      ));

      // Booking 4: Cancelled ($40)
      await bookingRepo.createBooking(BookingModel(
        id: 'bk_4',
        businessId: 'biz_metro',
        serviceId: 'srv_2',
        serviceName: 'Express Haircut',
        staffId: 'stf_2',
        staffName: 'Chloe Bennett',
        customerName: 'Diana Prince',
        customerPhone: '9990001111',
        startAt: now,
        endAt: now.add(const Duration(minutes: 30)),
        price: 40.0,
        status: BookingStatus.cancelled,
        cancellationReason: 'Sick',
      ));

      final analytics = await reportsRepo.computeRevenueAnalytics(
        'biz_metro',
        ReportPeriod.thisMonth,
      );

      // Verify Gross Revenue: 100 + 40 = $140
      expect(analytics.grossRevenue, 140.0);
      expect(analytics.completedCount, 2);

      // Verify Projected Revenue: $100
      expect(analytics.projectedRevenue, 100.0);
      expect(analytics.confirmedCount, 1);

      // Verify Lost Revenue: $40
      expect(analytics.lostRevenue, 40.0);
      expect(analytics.cancelledCount, 1);

      // Verify Total Bookings: 4
      expect(analytics.totalBookings, 4);

      // Verify Completion Rate: (2 / 4) * 100 = 50%
      expect(analytics.completionRate, 50.0);

      // Verify Cancellation Rate: (1 / 4) * 100 = 25%
      expect(analytics.cancellationRate, 25.0);

      // Verify Average Order Value: 140 / 2 = $70
      expect(analytics.averageOrderValue, 70.0);
    });

    test('Computes service analytics with revenue share percentage', () async {
      final now = DateTime.now();

      // 2 Massage bookings ($200 completed)
      await bookingRepo.createBooking(BookingModel(
        id: 'b_s1',
        businessId: 'biz_metro',
        serviceId: 'srv_1',
        serviceName: 'Full Body Massage',
        customerName: 'Client 1',
        customerPhone: '111',
        startAt: now,
        endAt: now.add(const Duration(minutes: 60)),
        price: 100.0,
        status: BookingStatus.completed,
      ));
      await bookingRepo.createBooking(BookingModel(
        id: 'b_s2',
        businessId: 'biz_metro',
        serviceId: 'srv_1',
        serviceName: 'Full Body Massage',
        customerName: 'Client 2',
        customerPhone: '222',
        startAt: now,
        endAt: now.add(const Duration(minutes: 60)),
        price: 100.0,
        status: BookingStatus.completed,
      ));

      // 1 Haircut booking ($50 completed)
      await bookingRepo.createBooking(BookingModel(
        id: 'b_s3',
        businessId: 'biz_metro',
        serviceId: 'srv_2',
        serviceName: 'Express Haircut',
        customerName: 'Client 3',
        customerPhone: '333',
        startAt: now,
        endAt: now.add(const Duration(minutes: 30)),
        price: 50.0,
        status: BookingStatus.completed,
      ));

      final serviceAnalytics = await reportsRepo.computeServiceAnalytics(
        'biz_metro',
        ReportPeriod.thisMonth,
      );

      expect(serviceAnalytics.length, 2);

      // Top service should be Massage with $200 revenue (80% share of $250)
      final topService = serviceAnalytics.first;
      expect(topService.serviceId, 'srv_1');
      expect(topService.revenue, 200.0);
      expect(topService.completedBookings, 2);
      expect(topService.shareOfTotalRevenue, closeTo(80.0, 0.1));

      // Second service should be Haircut with $50 revenue (20% share of $250)
      final secondService = serviceAnalytics[1];
      expect(secondService.serviceId, 'srv_2');
      expect(secondService.revenue, 50.0);
      expect(secondService.shareOfTotalRevenue, closeTo(20.0, 0.1));
    });

    test('Aggregates customer records, total spend, and repeat visits', () async {
      final now = DateTime.now();

      // Alice booked twice
      await bookingRepo.createBooking(BookingModel(
        id: 'b_c1',
        businessId: 'biz_metro',
        serviceId: 'srv_1',
        customerName: 'Alice Walker',
        customerPhone: '5551234',
        customerEmail: 'alice@example.com',
        startAt: now.subtract(const Duration(days: 10)),
        endAt: now.subtract(const Duration(days: 10)),
        price: 100.0,
        status: BookingStatus.completed,
      ));

      await bookingRepo.createBooking(BookingModel(
        id: 'b_c2',
        businessId: 'biz_metro',
        serviceId: 'srv_2',
        customerName: 'Alice Walker',
        customerPhone: '5551234',
        customerEmail: 'alice@example.com',
        startAt: now,
        endAt: now,
        price: 40.0,
        status: BookingStatus.completed,
      ));

      // Bob booked once
      await bookingRepo.createBooking(BookingModel(
        id: 'b_c3',
        businessId: 'biz_metro',
        serviceId: 'srv_2',
        customerName: 'Bob Stone',
        customerPhone: '5559876',
        startAt: now,
        endAt: now,
        price: 40.0,
        status: BookingStatus.completed,
      ));

      final customerRecords = await reportsRepo.computeCustomerRecords('biz_metro');

      expect(customerRecords.length, 2);

      // Alice should be first with $140 spent and 2 visits (Repeat Customer)
      final alice = customerRecords.first;
      expect(alice.customerName, 'Alice Walker');
      expect(alice.totalSpent, 140.0);
      expect(alice.totalBookings, 2);
      expect(alice.completedBookings, 2);
      expect(alice.isRepeatCustomer, true);

      // Bob should have 1 visit
      final bob = customerRecords[1];
      expect(bob.customerName, 'Bob Stone');
      expect(bob.totalSpent, 40.0);
      expect(bob.isRepeatCustomer, false);
    });
  });

  group('CSV Export Generation Tests', () {
    test('generateAppointmentsCsv generates valid RFC 4180 CSV with escaped fields', () {
      final now = DateTime(2026, 10, 20, 14, 30);
      final booking = BookingModel(
        id: 'bk_csv_01',
        businessId: 'biz_metro',
        serviceId: 'srv_1',
        serviceName: 'Massage, Spa & Relaxation', // contains comma
        staffId: 'stf_1',
        staffName: 'David "The Healer" Miller', // contains quotes
        customerName: 'Alice Smith',
        customerPhone: '+1 555-0199',
        customerEmail: 'alice@example.com',
        startAt: now,
        endAt: now.add(const Duration(minutes: 60)),
        price: 120.0,
        status: BookingStatus.completed,
      );

      final csv = CsvReportGenerator.generateAppointmentsCsv(
        bookings: [booking],
        businessName: 'Metro Spa',
        period: ReportPeriod.thisMonth,
      );

      expect(csv, contains('AppointmentPro - Appointments Report'));
      expect(csv, contains('Business: Metro Spa'));
      expect(csv, contains('"Booking ID","Date","Start Time"'));
      expect(csv, contains('"bk_csv_01"'));
      expect(csv, contains('"Massage, Spa & Relaxation"'));
      expect(csv, contains('"David ""The Healer"" Miller"'));
      expect(csv, contains('"Completed"'));
      expect(csv, contains('"120.00"'));
    });

    test('generateCustomerRecordsCsv formats customer directory correctly', () {
      final record = CustomerRecordModel(
        customerName: 'John Doe',
        customerPhone: '5551234',
        customerEmail: 'john@example.com',
        totalBookings: 3,
        completedBookings: 2,
        cancelledBookings: 1,
        totalSpent: 250.0,
        firstVisit: DateTime(2026, 8, 1),
        lastVisit: DateTime(2026, 10, 1),
      );

      final csv = CsvReportGenerator.generateCustomerRecordsCsv(
        customers: [record],
        businessName: 'Metro Spa',
      );

      expect(csv, contains('Customer Directory Report'));
      expect(csv, contains('"John Doe"'));
      expect(csv, contains('"5551234"'));
      expect(csv, contains('"250.00"'));
      expect(csv, contains('"Yes"')); // Repeat customer
    });
  });

  group('PDF Export Generation Tests', () {
    test('generateAppointmentsPdf produces valid PDF bytes', () async {
      final now = DateTime.now();
      final bookings = [
        BookingModel(
          id: 'bk_pdf_1',
          businessId: 'biz_metro',
          serviceId: 'srv_1',
          serviceName: 'Full Body Massage',
          customerName: 'Rohit Sharma',
          customerPhone: '9876543210',
          startAt: now,
          endAt: now.add(const Duration(minutes: 60)),
          price: 1500.0,
          status: BookingStatus.completed,
        ),
      ];

      final pdfBytes = await PdfReportGenerator.generateAppointmentsPdf(
        bookings: bookings,
        period: ReportPeriod.thisMonth,
        business: testBusiness,
      );

      expect(pdfBytes, isNotEmpty);
      // Validate PDF signature: %PDF (0x25, 0x50, 0x44, 0x46)
      expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
    });

    test('generateCustomerRecordsPdf produces valid PDF bytes', () async {
      final customers = [
        CustomerRecordModel(
          customerName: 'Priya Patel',
          customerPhone: '9123456780',
          customerEmail: 'priya@example.com',
          totalBookings: 4,
          completedBookings: 3,
          cancelledBookings: 1,
          totalSpent: 4500.0,
          firstVisit: DateTime(2026, 6, 1),
          lastVisit: DateTime(2026, 10, 1),
        ),
      ];

      final pdfBytes = await PdfReportGenerator.generateCustomerRecordsPdf(
        customers: customers,
        business: testBusiness,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
    });

    test('generateRevenueSummaryPdf produces valid PDF bytes', () async {
      final analytics = await reportsRepo.computeRevenueAnalytics(
        'biz_metro',
        ReportPeriod.thisMonth,
      );
      final services = await reportsRepo.computeServiceAnalytics(
        'biz_metro',
        ReportPeriod.thisMonth,
      );
      final staff = await reportsRepo.computeStaffAnalytics(
        'biz_metro',
        ReportPeriod.thisMonth,
      );

      final pdfBytes = await PdfReportGenerator.generateRevenueSummaryPdf(
        analytics: analytics,
        services: services,
        staff: staff,
        period: ReportPeriod.thisMonth,
        business: testBusiness,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
    });

    test('generateCustomerRecordsPdf handles em-dash and tricky unicode gracefully without missing font errors', () async {
      final trickyCustomers = [
        CustomerRecordModel(
          customerName: 'Special—Client “VIP” • Test',
          customerPhone: '',
          customerEmail: null,
          totalBookings: 1,
          completedBookings: 1,
          cancelledBookings: 0,
          totalSpent: 1000.0,
          firstVisit: DateTime.now(),
          lastVisit: DateTime.now(),
        ),
      ];

      final pdfBytes = await PdfReportGenerator.generateCustomerRecordsPdf(
        customers: trickyCustomers,
        business: testBusiness,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
    });
  });

  group('Reports & Analytics UI Tests', () {
    testWidgets('ReportsAnalyticsScreen renders KPI cards, period chips, and chart', (tester) async {
      final now = DateTime.now();

      await bookingRepo.createBooking(BookingModel(
        id: 'bk_ui_1',
        businessId: 'biz_metro',
        serviceId: 'srv_1',
        serviceName: 'Full Body Massage',
        customerName: 'Test Client',
        customerPhone: '9998887777',
        startAt: now,
        endAt: now.add(const Duration(minutes: 60)),
        price: 100.0,
        status: BookingStatus.completed,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeBusinessProvider.overrideWithValue(testBusiness),
            activeBusinessIdProvider.overrideWithValue('biz_metro'),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ReportsAnalyticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reports & Analytics'), findsOneWidget);
      expect(find.text('Gross Revenue'), findsOneWidget);
      expect(find.text('₹100.00'), findsWidgets);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.byType(AnalyticsKpiCard), findsWidgets);
      expect(find.byType(RevenueBarChart), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });
  });
}
