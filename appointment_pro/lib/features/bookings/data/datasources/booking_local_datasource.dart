import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../models/booking_model.dart';

class BookingLocalDataSource {
  final LocalStorageService _storage;

  static const String storageKey = 'appointmentpro_bookings';

  BookingLocalDataSource(this._storage);

  Future<List<BookingModel>> getBookings() async {
    final raw = await _storage.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final bookings = <BookingModel>[];

      for (final item in decoded) {
        try {
          if (item is Map<String, dynamic>) {
            bookings.add(BookingModel.fromJson(item));
          } else if (item is Map) {
            bookings.add(
              BookingModel.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        } catch (_) {
          // Gracefully skip corrupted individual records
        }
      }

      return bookings;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBookings(List<BookingModel> bookings) async {
    final encoded = jsonEncode(bookings.map((b) => b.toJson()).toList());
    await _storage.setString(storageKey, encoded);
  }

  Future<void> addBooking(BookingModel booking) async {
    final current = await getBookings();
    current.add(booking);
    await saveBookings(current);
  }

  Future<void> updateBooking(BookingModel booking) async {
    final current = await getBookings();
    final index = current.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      current[index] = booking;
      await saveBookings(current);
    }
  }

  Future<void> deleteBooking(String id) async {
    final current = await getBookings();
    current.removeWhere((b) => b.id == id);
    await saveBookings(current);
  }
}
