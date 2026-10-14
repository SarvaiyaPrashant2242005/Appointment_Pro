import '../datasources/booking_local_datasource.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final BookingLocalDataSource _dataSource;

  BookingRepository(this._dataSource);

  Future<List<BookingModel>> getBookings(String businessId) async {
    final all = await _dataSource.getBookings();
    final businessBookings = all
        .where((b) => b.businessId == businessId)
        .toList();

    // Sort by startAt ascending
    businessBookings.sort((a, b) => a.startAt.compareTo(b.startAt));
    return businessBookings;
  }

  Future<BookingModel?> getBookingById(String id) async {
    final all = await _dataSource.getBookings();
    return all.where((b) => b.id == id).firstOrNull;
  }

  Future<BookingModel> createBooking(BookingModel booking) async {
    await _dataSource.addBooking(booking);
    return booking;
  }

  Future<BookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus, {
    String? cancellationReason,
    DateTime? cancelledAt,
  }) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    // Validate status transition rules
    if (booking.status == BookingStatus.cancelled) {
      throw Exception('Cancelled bookings cannot be modified.');
    }
    if (booking.status == BookingStatus.completed) {
      throw Exception('Completed bookings cannot be modified.');
    }
    if (booking.status == BookingStatus.noShow) {
      throw Exception('No-show bookings cannot be modified.');
    }

    if (newStatus == BookingStatus.completed && !booking.canComplete) {
      throw Exception('Only confirmed bookings can be marked as completed.');
    }
    if (newStatus == BookingStatus.noShow && !booking.canMarkNoShow) {
      throw Exception('Only confirmed bookings can be marked as no-show.');
    }
    if (newStatus == BookingStatus.cancelled && !booking.canCancel) {
      throw Exception('This booking cannot be cancelled.');
    }

    final isCancelling = newStatus == BookingStatus.cancelled;
    final updated = booking.copyWith(
      status: newStatus,
      cancellationReason: isCancelling
          ? (cancellationReason ?? booking.cancellationReason)
          : booking.cancellationReason,
      cancelledAt: isCancelling
          ? (cancelledAt ?? booking.cancelledAt ?? DateTime.now())
          : booking.cancelledAt,
      updatedAt: DateTime.now(),
    );

    await _dataSource.updateBooking(updated);
    return updated;
  }

  /// Reschedules an existing booking, preserving the booking ID and customer details
  Future<BookingModel> rescheduleBooking({
    required String bookingId,
    required DateTime newStartAt,
    required DateTime newEndAt,
    String? newStaffId,
    String? newStaffName,
    String? reason,
  }) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    if (!booking.canReschedule) {
      throw Exception(
        'Only active bookings can be rescheduled. This booking is ${booking.status.displayName.toLowerCase()}.',
      );
    }

    final historyRecord = RescheduleRecord(
      previousStartAt: booking.startAt,
      previousEndAt: booking.endAt,
      newStartAt: newStartAt,
      newEndAt: newEndAt,
      rescheduledAt: DateTime.now(),
      previousStaffId: booking.staffId,
      newStaffId: newStaffId ?? booking.staffId,
      reason: reason,
    );

    final updated = booking.copyWith(
      startAt: newStartAt,
      endAt: newEndAt,
      staffId: newStaffId ?? booking.staffId,
      staffName: newStaffName ?? booking.staffName,
      updatedAt: DateTime.now(),
      rescheduleHistory: [...booking.rescheduleHistory, historyRecord],
    );

    await _dataSource.updateBooking(updated);
    return updated;
  }

  Future<List<BookingModel>> getBookingsForDate(
    String businessId,
    DateTime date,
  ) async {
    final list = await getBookings(businessId);
    return list.where((b) {
      return b.startAt.year == date.year &&
          b.startAt.month == date.month &&
          b.startAt.day == date.day;
    }).toList();
  }

  Future<List<BookingModel>> getBookingsForStaff(
    String businessId,
    String staffId,
    DateTime date,
  ) async {
    final dayBookings = await getBookingsForDate(businessId, date);
    return dayBookings.where((b) => b.staffId == staffId).toList();
  }
}
