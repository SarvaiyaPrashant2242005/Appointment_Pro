import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../models/availability_model.dart';

class AvailabilityRepository {
  final LocalStorageService _storage;

  AvailabilityRepository(this._storage);

  String _availabilityKey(String businessId) =>
      'appointmentpro_availability_$businessId';
  String _timeOffKey(String businessId) => 'appointmentpro_timeoff_$businessId';

  Future<BusinessAvailability> getBusinessAvailability(
    String businessId,
  ) async {
    final raw = await _storage.getString(_availabilityKey(businessId));
    if (raw == null || raw.trim().isEmpty) {
      return BusinessAvailability.defaultFor(businessId);
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final availability = BusinessAvailability.fromJson(decoded);
      // Ensure all 7 days exist
      if (availability.weeklySchedule.length < 7) {
        final def = BusinessAvailability.defaultFor(businessId);
        final merged = Map<int, DaySchedule>.from(def.weeklySchedule)
          ..addAll(availability.weeklySchedule);
        return availability.copyWith(weeklySchedule: merged);
      }
      return availability;
    } catch (_) {
      return BusinessAvailability.defaultFor(businessId);
    }
  }

  Future<void> saveBusinessAvailability(
    BusinessAvailability availability,
  ) async {
    final encoded = jsonEncode(availability.toJson());
    await _storage.setString(
      _availabilityKey(availability.businessId),
      encoded,
    );
  }

  Future<List<TimeOffRecord>> getTimeOffRecords(
    String businessId, {
    String? staffId,
  }) async {
    final raw = await _storage.getString(_timeOffKey(businessId));
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map(
            (item) =>
                TimeOffRecord.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .where((r) => r.businessId == businessId)
          .toList();

      if (staffId != null) {
        return list
            .where((r) => r.staffId == staffId || r.isBusinessWide)
            .toList();
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> addTimeOff(TimeOffRecord record) async {
    final current = await getTimeOffRecords(record.businessId);
    current.add(record);
    final encoded = jsonEncode(current.map((r) => r.toJson()).toList());
    await _storage.setString(_timeOffKey(record.businessId), encoded);
  }

  Future<void> updateTimeOff(TimeOffRecord updated) async {
    final current = await getTimeOffRecords(updated.businessId);
    final index = current.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      current[index] = updated;
      final encoded = jsonEncode(current.map((r) => r.toJson()).toList());
      await _storage.setString(_timeOffKey(updated.businessId), encoded);
    }
  }

  Future<void> deleteTimeOff(String businessId, String id) async {
    final current = await getTimeOffRecords(businessId);
    current.removeWhere((r) => r.id == id);
    final encoded = jsonEncode(current.map((r) => r.toJson()).toList());
    await _storage.setString(_timeOffKey(businessId), encoded);
  }
}
