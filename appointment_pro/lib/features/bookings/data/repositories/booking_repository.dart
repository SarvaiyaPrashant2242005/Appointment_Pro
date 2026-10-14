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

    if (newStatus == BookingStatus.confirmed && !booking.canConfirm) {
      throw Exception('Only pending bookings can be confirmed.');
    }
    if (newStatus == BookingStatus.completed && !booking.canComplete) {
      throw Exception('Only confirmed bookings can be marked as completed.');
    }
    if (newStatus == BookingStatus.noShow && !booking.canMarkNoShow) {
      throw Exception('Only confirmed bookings can be marked as no-show.');
    }

    final updated = booking.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
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
