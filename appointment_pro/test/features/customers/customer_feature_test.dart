import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/bookings/data/models/booking_model.dart';
import 'package:appointment_pro/features/bookings/presentation/providers/booking_provider.dart';
import 'package:appointment_pro/features/bussiness_setup/presentation/providers/business_provider.dart';
import 'package:appointment_pro/features/customers/data/models/customer_model.dart';
import 'package:appointment_pro/features/customers/data/repositories/customer_repository.dart';
import 'package:appointment_pro/features/customers/presentation/providers/customer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerModel Tests', () {
    test('initials extracts first and last initials, or single initial', () {
      final customerMulti = CustomerModel(
        id: 'c1',
        businessId: 'b1',
        name: 'Johnathan Doe',
        phone: '9876543210',
      );
      expect(customerMulti.initials, 'JD');

      final customerSingle = CustomerModel(
        id: 'c2',
        businessId: 'b1',
        name: 'Madonna',
        phone: '9876543210',
      );
      expect(customerSingle.initials, 'M');

      final customerEmpty = CustomerModel(
        id: 'c3',
        businessId: 'b1',
        name: '',
        phone: '9876543210',
      );
      expect(customerEmpty.initials, '?');
    });

    test('formattedPhone prepends countryCode if not already prefixed', () {
      final c1 = CustomerModel(
        id: 'c1',
        businessId: 'b1',
        name: 'Alice',
        countryCode: '+91',
        phone: '9876543210',
      );
      expect(c1.formattedPhone, '+91 9876543210');

      final c2 = CustomerModel(
        id: 'c2',
        businessId: 'b1',
        name: 'Bob',
        phone: '+1 5551234567',
      );
      expect(c2.formattedPhone, '+1 5551234567');
    });

    test('round-trip JSON serialization and deserialization', () {
      final now = DateTime.now();
      final customer = CustomerModel(
        id: 'cust_101',
        businessId: 'biz_aura',
        name: 'Sophia Loren',
        countryCode: '+39',
        phone: '0612345678',
        email: 'sophia@cinema.it',
        notes: 'Prefers lavender essential oil',
        totalBookings: 5,
        lastBookingAt: now,
      );

      final json = customer.toJson();
      final fromJson = CustomerModel.fromJson(json);

      expect(fromJson.id, 'cust_101');
      expect(fromJson.businessId, 'biz_aura');
      expect(fromJson.name, 'Sophia Loren');
      expect(fromJson.countryCode, '+39');
      expect(fromJson.phone, '0612345678');
      expect(fromJson.email, 'sophia@cinema.it');
      expect(fromJson.notes, 'Prefers lavender essential oil');
      expect(fromJson.totalBookings, 5);
      expect(fromJson.lastBookingAt?.day, now.day);
    });

    test('fromJson handles snake_case backend keys gracefully', () {
      final backendJson = {
        'id': 'cust_999',
        'business_id': 'biz_metro',
        'name': 'Carlos Santana',
        'country_code': '+52',
        'phone': '5511223344',
        'total_bookings': 3,
        'created_at': '2026-05-10T10:00:00.000Z',
      };

      final customer = CustomerModel.fromJson(backendJson);
      expect(customer.id, 'cust_999');
      expect(customer.businessId, 'biz_metro');
      expect(customer.countryCode, '+52');
      expect(customer.totalBookings, 3);
    });
  });

  group('CustomerRepository Local Storage Tests', () {
    late LocalStorageService storage;
    late CustomerRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs);
      repository = CustomerRepository(storage);
    });

    test('createCustomer and getCustomers for business', () async {
      final c1 = CustomerModel(
        id: 'c1',
        businessId: 'biz_test',
        name: 'Emma Watson',
        phone: '9991112222',
        email: 'emma@test.com',
      );
      final c2 = CustomerModel(
        id: 'c2',
        businessId: 'biz_other',
        name: 'Dan Radcliffe',
        phone: '9993334444',
      );

      await repository.createCustomer(c1);
      await repository.createCustomer(c2);

      final bizCustomers = await repository.getCustomers('biz_test');
      expect(bizCustomers.length, 1);
      expect(bizCustomers.first.name, 'Emma Watson');

      // Search filter
      final searchResult = await repository.getCustomers(
        'biz_test',
        search: 'emma',
      );
      expect(searchResult.length, 1);

      final searchEmpty = await repository.getCustomers(
        'biz_test',
        search: 'nonexistent',
      );
      expect(searchEmpty.isEmpty, true);
    });

    test('updateCustomer updates existing customer details', () async {
      final customer = CustomerModel(
        id: 'c10',
        businessId: 'biz_test',
        name: 'Bruce Wayne',
        phone: '9888888888',
        notes: 'VIP Client',
      );
      await repository.createCustomer(customer);

      final updated = customer.copyWith(notes: 'Prefers night appointments');
      await repository.updateCustomer(updated);

      final fetched = await repository.getCustomerById('c10');
      expect(fetched?.notes, 'Prefers night appointments');
    });

    test('deleteCustomer removes customer from repository', () async {
      final customer = CustomerModel(
        id: 'c20',
        businessId: 'biz_test',
        name: 'Clark Kent',
        phone: '9777777777',
      );
      await repository.createCustomer(customer);

      var list = await repository.getCustomers('biz_test');
      expect(list.length, 1);

      await repository.deleteCustomer('c20');
      list = await repository.getCustomers('biz_test');
      expect(list.isEmpty, true);
    });
  });

  group('Customer Riverpod State & Filtering Tests', () {
    late LocalStorageService storage;
    late CustomerRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs);
      repository = CustomerRepository(storage);

      await repository.createCustomer(CustomerModel(
        id: 'c_repeat',
        businessId: 'biz_1',
        name: 'Diana Prince',
        phone: '5550001111',
        totalBookings: 4,
      ));
      await repository.createCustomer(CustomerModel(
        id: 'c_first',
        businessId: 'biz_1',
        name: 'Barry Allen',
        phone: '5552223333',
        totalBookings: 1,
      ));
    });

    test('filteredCustomersProvider filters by query and filter type', () async {
      // Verify initial unfiltered state
      final element = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          customerRepositoryProvider.overrideWithValue(repository),
          activeBusinessIdProvider.overrideWithValue('biz_1'),
          bookingsProvider.overrideWith(() => _FakeBookingsController()),
        ],
      );

      final customers = await element.read(customersProvider.future);
      expect(customers.length, 2);

      // Search filter
      element.read(customerSearchQueryProvider.notifier).state = 'barry';
      var filtered = element.read(filteredCustomersProvider);
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Barry Allen');

      // Clear search
      element.read(customerSearchQueryProvider.notifier).state = '';

      // Segment filter: returning
      element.read(customerFilterTypeProvider.notifier).state =
          CustomerFilterType.returning;
      filtered = element.read(filteredCustomersProvider);
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Diana Prince');

      // Segment filter: new
      element.read(customerFilterTypeProvider.notifier).state =
          CustomerFilterType.newClients;
      filtered = element.read(filteredCustomersProvider);
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Barry Allen');

      // Stats provider
      final stats = element.read(customerStatsProvider);
      expect(stats['total'], 2);
      expect(stats['returning'], 1);
      expect(stats['totalBookings'], 5);
    });
  });
}

class _FakeBookingsController extends BookingsController {
  @override
  Future<List<BookingModel>> build() async => [];
}

class _TestConsumer extends ConsumerWidget {
  const _TestConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox();
}
