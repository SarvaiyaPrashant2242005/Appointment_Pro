import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/datasources/booking_local_datasource.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';

/// Provider for BookingLocalDataSource
final bookingLocalDataSourceProvider = Provider<BookingLocalDataSource>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return BookingLocalDataSource(storage);
});

/// Provider for BookingRepository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final dataSource = ref.watch(bookingLocalDataSourceProvider);
  return BookingRepository(dataSource);
});

/// Main controller managing owner bookings for the active business
final bookingsProvider =
    AsyncNotifierProvider<BookingsController, List<BookingModel>>(
      BookingsController.new,
    );

class BookingsController extends AsyncNotifier<List<BookingModel>> {
  late BookingRepository _repository;

  @override
  Future<List<BookingModel>> build() async {
    _repository = ref.watch(bookingRepositoryProvider);
    final businessId = ref.watch(activeBusinessIdProvider);

    if (businessId == null || businessId.isEmpty) {
      return [];
    }

    return _repository.getBookings(businessId);
  }

  /// Create a new booking (scoped to active business or provided booking's business)
  Future<BookingModel> createBooking(BookingModel booking) async {
    final businessId = ref.read(activeBusinessIdProvider) ?? booking.businessId;
    final scopedBooking = booking.copyWith(businessId: businessId);
    final previous = state.asData?.value ?? [];

    try {
      final created = await _repository.createBooking(scopedBooking);
      state = AsyncData(
        [...previous, created]..sort((a, b) => a.startAt.compareTo(b.startAt)),
      );
      return created;
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Confirm a pending booking
  Future<void> confirmBooking(String id) async {
    final previous = state.asData?.value ?? [];
    try {
      final updated = await _repository.updateBookingStatus(
        id,
        BookingStatus.confirmed,
      );
      state = AsyncData(previous.map((b) => b.id == id ? updated : b).toList());
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String id, {String? reason}) async {
    final previous = state.asData?.value ?? [];
    try {
      final updated = await _repository.updateBookingStatus(
        id,
        BookingStatus.cancelled,
        cancellationReason: reason,
      );
      state = AsyncData(previous.map((b) => b.id == id ? updated : b).toList());
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Mark booking as completed
  Future<void> completeBooking(String id) async {
    final previous = state.asData?.value ?? [];
    try {
      final updated = await _repository.updateBookingStatus(
        id,
        BookingStatus.completed,
      );
      state = AsyncData(previous.map((b) => b.id == id ? updated : b).toList());
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Mark booking as no-show
  Future<void> markNoShow(String id) async {
    final previous = state.asData?.value ?? [];
    try {
      final updated = await _repository.updateBookingStatus(
        id,
        BookingStatus.noShow,
      );
      state = AsyncData(previous.map((b) => b.id == id ? updated : b).toList());
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Refresh bookings
  Future<void> refresh() async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getBookings(businessId));
  }
}

/// Filter tab for booking list
enum BookingListTab { today, upcoming, past }

final bookingTabProvider = NotifierProvider<BookingTabNotifier, BookingListTab>(
  BookingTabNotifier.new,
);

class BookingTabNotifier extends Notifier<BookingListTab> {
  @override
  BookingListTab build() => BookingListTab.today;

  void selectTab(BookingListTab tab) => state = tab;
}

/// Search filter query for owner booking list
final bookingSearchQueryProvider =
    NotifierProvider<BookingSearchNotifier, String>(BookingSearchNotifier.new);

class BookingSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
}

/// Status filter for owner booking list (null means all)
final bookingStatusFilterProvider =
    NotifierProvider<BookingStatusFilterNotifier, BookingStatus?>(
      BookingStatusFilterNotifier.new,
    );

class BookingStatusFilterNotifier extends Notifier<BookingStatus?> {
  @override
  BookingStatus? build() => null;

  void setFilter(BookingStatus? status) => state = status;
}

/// Filtered bookings based on tab, status filter, and search query
final filteredBookingsProvider = Provider<List<BookingModel>>((ref) {
  final allBookings = ref.watch(bookingsProvider).value ?? [];
  final activeTab = ref.watch(bookingTabProvider);
  final statusFilter = ref.watch(bookingStatusFilterProvider);
  final query = ref.watch(bookingSearchQueryProvider).trim().toLowerCase();

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return allBookings.where((booking) {
    // 1. Tab filter
    switch (activeTab) {
      case BookingListTab.today:
        if (booking.startAt.isBefore(startOfToday) ||
            booking.startAt.isAfter(endOfToday)) {
          return false;
        }
        break;
      case BookingListTab.upcoming:
        if (booking.startAt.isBefore(endOfToday)) {
          return false;
        }
        break;
      case BookingListTab.past:
        if (booking.startAt.isAfter(startOfToday)) {
          return false;
        }
        break;
    }

    // 2. Status filter
    if (statusFilter != null && booking.status != statusFilter) {
      return false;
    }

    // 3. Search query filter (customer name, phone, or service ID)
    if (query.isNotEmpty) {
      final nameMatches = booking.customerName.toLowerCase().contains(query);
      final phoneMatches = booking.customerPhone.contains(query);
      final notesMatches = (booking.customerNotes ?? '').toLowerCase().contains(
        query,
      );
      if (!nameMatches && !phoneMatches && !notesMatches) {
        return false;
      }
    }

    return true;
  }).toList();
});

/// Bookings for today (used on dashboard and quick stats)
final todayBookingsProvider = Provider<List<BookingModel>>((ref) {
  final all = ref.watch(bookingsProvider).value ?? [];
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return all
      .where(
        (b) =>
            !b.startAt.isBefore(startOfToday) && !b.startAt.isAfter(endOfToday),
      )
      .toList();
});

/// Single booking lookup provider by ID
final bookingByIdProvider = Provider.family<BookingModel?, String>((ref, id) {
  final all = ref.watch(bookingsProvider).value ?? [];
  return all.where((b) => b.id == id).firstOrNull;
});
