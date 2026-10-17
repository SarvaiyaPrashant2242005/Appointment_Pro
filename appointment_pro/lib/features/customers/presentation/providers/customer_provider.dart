import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(localStorageServiceProvider);
  return CustomerRepository(apiClient, storage);
});

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final customersProvider =
    AsyncNotifierProvider<CustomersController, List<CustomerModel>>(
      CustomersController.new,
    );

class CustomersController extends AsyncNotifier<List<CustomerModel>> {
  late CustomerRepository _repository;

  @override
  Future<List<CustomerModel>> build() async {
    _repository = ref.watch(customerRepositoryProvider);
    final businessId = ref.watch(activeBusinessIdProvider);

    if (businessId == null || businessId.isEmpty) {
      return [];
    }

    final customers = await _repository.getCustomers(businessId);

    // Also enrich with booking history stats if bookings are loaded
    final bookings = ref.watch(bookingsProvider).value ?? [];
    if (bookings.isNotEmpty) {
      return customers.map((c) {
        final matchingBookings = bookings.where((b) {
          final phoneMatches =
              b.customerPhone.replaceAll(RegExp(r'\s+'), '') ==
              c.phone.replaceAll(RegExp(r'\s+'), '');
          return phoneMatches ||
              b.customerName.toLowerCase() == c.name.toLowerCase();
        }).toList();

        if (matchingBookings.isEmpty) return c;

        matchingBookings.sort((a, b) => b.startAt.compareTo(a.startAt));
        final lastVisit = matchingBookings.first.startAt;

        return c.copyWith(
          totalBookings: matchingBookings.length,
          lastBookingAt: lastVisit,
        );
      }).toList();
    }

    return customers;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> createCustomer(CustomerModel customer) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) {
      throw Exception('No active business selected');
    }

    final scopedCustomer = customer.copyWith(businessId: businessId);
    final previous = state.asData?.value ?? [];

    try {
      final created = await _repository.createCustomer(scopedCustomer);
      state = AsyncData([...previous, created]);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateCustomer(CustomerModel updated) async {
    final previous = state.asData?.value ?? [];

    try {
      final saved = await _repository.updateCustomer(updated);
      final updatedList = previous
          .map((c) => c.id == saved.id ? saved : c)
          .toList();
      state = AsyncData(updatedList);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    final previous = state.asData?.value ?? [];

    try {
      await _repository.deleteCustomer(customerId);
      final updatedList = previous.where((c) => c.id != customerId).toList();
      state = AsyncData(updatedList);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

enum CustomerFilterType { all, returning, newClients }

final customerFilterTypeProvider =
    StateProvider<CustomerFilterType>((ref) => CustomerFilterType.all);

/// Filtered customers according to the current search query and selected filter tab
final filteredCustomersProvider = Provider<List<CustomerModel>>((ref) {
  final customers = ref.watch(customersProvider).value ?? [];
  final query = ref.watch(customerSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(customerFilterTypeProvider);

  return customers.where((c) {
    if (filter == CustomerFilterType.returning && c.totalBookings <= 1) {
      return false;
    }
    if (filter == CustomerFilterType.newClients && c.totalBookings > 1) {
      return false;
    }

    if (query.isEmpty) return true;

    return c.name.toLowerCase().contains(query) ||
        c.phone.contains(query) ||
        (c.email != null && c.email!.toLowerCase().contains(query)) ||
        (c.notes != null && c.notes!.toLowerCase().contains(query));
  }).toList();
});

/// Metrics summary for customers
final customerStatsProvider = Provider<Map<String, int>>((ref) {
  final customers = ref.watch(customersProvider).value ?? [];
  final returning = customers.where((c) => c.totalBookings > 1).length;
  final totalBookings =
      customers.fold<int>(0, (sum, c) => sum + c.totalBookings);

  return {
    'total': customers.length,
    'returning': returning,
    'totalBookings': totalBookings,
  };
});

/// Retrieve all bookings associated with a specific customer
final customerBookingsProvider =
    Provider.family<List<BookingModel>, CustomerModel>((ref, customer) {
      final allBookings = ref.watch(bookingsProvider).value ?? [];
      return allBookings.where((b) {
        final cleanCustomerPhone = customer.phone.replaceAll(
          RegExp(r'\s+'),
          '',
        );
        final cleanBookingPhone = b.customerPhone.replaceAll(
          RegExp(r'\s+'),
          '',
        );
        return cleanBookingPhone == cleanCustomerPhone ||
            b.customerName.toLowerCase() == customer.name.toLowerCase();
      }).toList();
    });
