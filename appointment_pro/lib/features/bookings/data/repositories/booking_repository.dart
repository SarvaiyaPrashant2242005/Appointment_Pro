import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/api_client.dart';
import '../datasources/booking_local_datasource.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final ApiClient? _apiClient;
  final BookingLocalDataSource? _dataSource;

  BookingRepository(dynamic clientOrDataSource, [BookingLocalDataSource? dataSource])
      : _apiClient = clientOrDataSource is ApiClient ? clientOrDataSource : null,
        _dataSource = clientOrDataSource is BookingLocalDataSource
            ? clientOrDataSource
            : dataSource;

  Future<List<BookingModel>> getBookings(
    String businessId, {
    String? status,
    String? date,
  }) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final query = <String, dynamic>{
          if (businessId.isNotEmpty) 'businessId': businessId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (date != null && date.isNotEmpty) 'date': date,
        };

        final response = await client.get(
          ApiEndpoints.bookings,
          queryParameters: query,
        );
        final rawData = response['data'];

        if (rawData is List) {
          final list = rawData
              .map(
                (item) =>
                    BookingModel.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
          list.sort((a, b) => a.startAt.compareTo(b.startAt));
          return list;
        }
        return [];
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    final ds = _dataSource;
    if (ds != null) {
      final all = await ds.getBookings();
      final businessBookings = all
          .where(
            (b) =>
                businessId.isEmpty ||
                b.businessId.isEmpty ||
                b.businessId == businessId,
          )
          .toList();

      businessBookings.sort((a, b) => a.startAt.compareTo(b.startAt));
      return businessBookings;
    }

    return [];
  }

  Future<BookingModel?> getBookingById(String id) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final response = await client.get(ApiEndpoints.bookingById(id));
        final rawData = response['data'];
        if (rawData is Map) {
          return BookingModel.fromJson(Map<String, dynamic>.from(rawData));
        }
        return null;
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    final ds = _dataSource;
    if (ds != null) {
      final all = await ds.getBookings();
      return all
          .where(
            (b) =>
                b.id == id ||
                b.bookingReference == id ||
                b.displayId == id,
          )
          .firstOrNull;
    }

    return null;
  }

  Future<BookingModel?> getBookingByReference(String bookingReference) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final response = await client.get(
          ApiEndpoints.bookingByRef(bookingReference),
        );
        final rawData = response['data'];
        if (rawData is Map) {
          return BookingModel.fromJson(Map<String, dynamic>.from(rawData));
        }
        return null;
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    final ds = _dataSource;
    if (ds != null) {
      final all = await ds.getBookings();
      return all
          .where(
            (b) =>
                b.id == bookingReference ||
                b.bookingReference == bookingReference ||
                b.displayId == bookingReference,
          )
          .firstOrNull;
    }

    return null;
  }

  Future<BookingModel> createBooking(BookingModel booking) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final body = {
          'businessId': booking.businessId,
          'serviceId': booking.serviceId,
          if (booking.staffId != null && booking.staffId!.isNotEmpty)
            'staffId': booking.staffId,
          'customerName': booking.customerName,
          'customerCountryCode': booking.customerCountryCode,
          'customerPhone': booking.customerPhone,
          if (booking.customerEmail != null &&
              booking.customerEmail!.trim().isNotEmpty)
            'customerEmail': booking.customerEmail!.trim(),
          if (booking.customerNotes != null &&
              booking.customerNotes!.trim().isNotEmpty)
            'customerNotes': booking.customerNotes!.trim(),
          'startAt': booking.startAt.toIso8601String(),
          'endAt': booking.endAt.toIso8601String(),
          'price': booking.price,
        };

        final response = await client.post(
          ApiEndpoints.bookings,
          data: body,
        );
        final data = response['data'] as Map<String, dynamic>;
        return BookingModel.fromJson(data);
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    final ds = _dataSource;
    if (ds != null) {
      await ds.addBooking(booking);
      return booking;
    }

    return booking;
  }

  Future<BookingModel> createPublicBooking(
    String businessSlug,
    BookingModel booking,
  ) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final body = {
          'serviceId': booking.serviceId,
          if (booking.staffId != null && booking.staffId!.isNotEmpty)
            'staffId': booking.staffId,
          'customerName': booking.customerName,
          'customerCountryCode': booking.customerCountryCode,
          'customerPhone': booking.customerPhone,
          if (booking.customerEmail != null &&
              booking.customerEmail!.trim().isNotEmpty)
            'customerEmail': booking.customerEmail!.trim(),
          if (booking.customerNotes != null &&
              booking.customerNotes!.trim().isNotEmpty)
            'customerNotes': booking.customerNotes!.trim(),
          'startAt': booking.startAt.toIso8601String(),
        };

        final response = await client.post(
          ApiEndpoints.bookingPublic(businessSlug),
          data: body,
        );
        final data = response['data'] as Map<String, dynamic>;
        return BookingModel.fromJson(data);
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    final ds = _dataSource;
    if (ds != null) {
      await ds.addBooking(booking);
      return booking;
    }

    return booking;
  }

  Future<BookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus, {
    String? cancellationReason,
    DateTime? cancelledAt,
  }) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final body = {
          'status': newStatus.name,
          if (cancellationReason != null && cancellationReason.trim().isNotEmpty)
            'cancellationReason': cancellationReason.trim(),
        };

        final response = await client.patch(
          ApiEndpoints.bookingStatus(bookingId),
          data: body,
        );
        final data = response['data'] as Map<String, dynamic>;
        return BookingModel.fromJson(data);
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    final booking = await getBookingById(bookingId) ??
        await getBookingByReference(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

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

    final ds = _dataSource;
    if (ds != null) {
      await ds.updateBooking(updated);
    }
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
    final client = _apiClient;
    if (client != null) {
      try {
        final body = {
          'newStartAt': newStartAt.toIso8601String(),
          'newEndAt': newEndAt.toIso8601String(),
          if (newStaffId != null && newStaffId.isNotEmpty)
            'newStaffId': newStaffId,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        };

        final response = await client.patch(
          ApiEndpoints.bookingReschedule(bookingId),
          data: body,
        );
        final data = response['data'] as Map<String, dynamic>;
        return BookingModel.fromJson(data);
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    final booking = await getBookingById(bookingId) ??
        await getBookingByReference(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    if (!booking.canReschedule) {
      throw Exception(
        'Only active bookings can be rescheduled. This booking is ${booking.status.displayName.toLowerCase()}.',
      );
    }

    final record = RescheduleRecord(
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
      rescheduleHistory: [...booking.rescheduleHistory, record],
      updatedAt: DateTime.now(),
    );

    final ds = _dataSource;
    if (ds != null) {
      await ds.updateBooking(updated);
    }
    return updated;
  }

  /// Public customer cancellation using public-cancel endpoint
  Future<BookingModel> publicCancelBooking(
    String bookingId, {
    String? cancellationReason,
  }) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final body = {
          if (cancellationReason != null && cancellationReason.trim().isNotEmpty)
            'cancellationReason': cancellationReason.trim(),
        };

        final response = await client.patch(
          ApiEndpoints.bookingPublicCancel(bookingId),
          data: body,
        );
        final data = response['data'] as Map<String, dynamic>;
        return BookingModel.fromJson(data);
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    return updateBookingStatus(
      bookingId,
      BookingStatus.cancelled,
      cancellationReason: cancellationReason,
    );
  }

  /// Public customer reschedule using public-reschedule endpoint
  Future<BookingModel> publicRescheduleBooking({
    required String bookingId,
    required DateTime newStartAt,
    required DateTime newEndAt,
    String? newStaffId,
    String? newStaffName,
    String? reason,
  }) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final body = {
          'newStartAt': newStartAt.toIso8601String(),
          'newEndAt': newEndAt.toIso8601String(),
          if (newStaffId != null && newStaffId.isNotEmpty)
            'newStaffId': newStaffId,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        };

        final response = await client.patch(
          ApiEndpoints.bookingPublicReschedule(bookingId),
          data: body,
        );
        final data = response['data'] as Map<String, dynamic>;
        return BookingModel.fromJson(data);
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    return rescheduleBooking(
      bookingId: bookingId,
      newStartAt: newStartAt,
      newEndAt: newEndAt,
      newStaffId: newStaffId,
      newStaffName: newStaffName,
      reason: reason,
    );
  }

  Future<void> deleteBooking(String id) async {
    final client = _apiClient;
    if (client != null) {
      try {
        await client.delete(ApiEndpoints.bookingById(id));
        return;
      } catch (e) {
        if (_dataSource == null) rethrow;
      }
    }

    final ds = _dataSource;
    if (ds != null) {
      await ds.deleteBooking(id);
    }
  }
}
