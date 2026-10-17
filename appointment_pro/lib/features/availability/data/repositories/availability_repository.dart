import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/availability_model.dart';

class AvailabilityRepository {
  final ApiClient? _apiClient;
  final LocalStorageService? _storage;

  AvailabilityRepository(dynamic clientOrStorage, [LocalStorageService? storage])
      : _apiClient = clientOrStorage is ApiClient ? clientOrStorage : null,
        _storage = clientOrStorage is LocalStorageService
            ? clientOrStorage
            : storage;

  String _availabilityKey(String businessId) =>
      'appointmentpro_availability_$businessId';
  String _timeOffKey(String businessId) => 'appointmentpro_timeoff_$businessId';

  /// Fetch business operating hours and breaks from the backend API
  Future<BusinessAvailability> getBusinessAvailability(
    String businessId,
  ) async {
    if (businessId.isEmpty) {
      return BusinessAvailability.defaultFor('');
    }

    if (_apiClient != null) {
      try {
        final response = await _apiClient!.get(
          ApiEndpoints.operatingHours,
          queryParameters: {'businessId': businessId},
        );

        final data = response['data'];
        if (data is Map) {
          final parsed = BusinessAvailability.fromJson(
            Map<String, dynamic>.from(data),
          );
          // Ensure all 7 days exist
          if (parsed.weeklySchedule.length < 7) {
            final def = BusinessAvailability.defaultFor(businessId);
            final merged = Map<int, DaySchedule>.from(def.weeklySchedule)
              ..addAll(parsed.weeklySchedule);
            return parsed.copyWith(weeklySchedule: merged);
          }
          return parsed;
        }
        return BusinessAvailability.defaultFor(businessId);
      } catch (_) {
        // Fallback to default if network error or setup pending
        return BusinessAvailability.defaultFor(businessId);
      }
    }

    if (_storage != null) {
      final raw = await _storage!.getString(_availabilityKey(businessId));
      if (raw == null || raw.trim().isEmpty) {
        return BusinessAvailability.defaultFor(businessId);
      }
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final availability = BusinessAvailability.fromJson(decoded);
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

    return BusinessAvailability.defaultFor(businessId);
  }

  /// Save or update business operating hours and breaks to the API
  Future<BusinessAvailability> saveBusinessAvailability(
    BusinessAvailability availability,
  ) async {
    if (_apiClient != null) {
      final payload = {
        'businessId': availability.businessId,
        'weeklySchedule': availability.weeklySchedule.map(
          (k, v) => MapEntry(k.toString(), v.toJson()),
        ),
        'timezone': availability.timezone,
      };

      final response = await _apiClient!.put(
        ApiEndpoints.operatingHours,
        data: payload,
      );

      final data = response['data'];
      if (data is Map) {
        return BusinessAvailability.fromJson(Map<String, dynamic>.from(data));
      }
      return availability;
    }

    if (_storage != null) {
      final encoded = jsonEncode(availability.toJson());
      await _storage!.setString(
        _availabilityKey(availability.businessId),
        encoded,
      );
    }

    return availability;
  }

  /// Toggle single day status (open/closed) via backend endpoint
  Future<DaySchedule> toggleDayStatus(String businessId, int dayOfWeek) async {
    if (_apiClient != null) {
      final response = await _apiClient!.patch(
        ApiEndpoints.availabilityToggle(dayOfWeek),
        data: {'businessId': businessId},
      );

      final data = response['data'] as Map<String, dynamic>;
      return DaySchedule.fromJson(data);
    }

    final availability = await getBusinessAvailability(businessId);
    final day = availability.weeklySchedule[dayOfWeek];
    if (day != null) {
      final updatedDay = day.copyWith(isOpen: !day.isOpen);
      final updatedMap = Map<int, DaySchedule>.from(availability.weeklySchedule)
        ..[dayOfWeek] = updatedDay;
      await saveBusinessAvailability(
        availability.copyWith(weeklySchedule: updatedMap),
      );
      return updatedDay;
    }
    throw Exception('Day $dayOfWeek not found');
  }

  /// Public lookup by business booking link slug
  Future<BusinessAvailability> getPublicOperatingHours(String slug) async {
    if (_apiClient != null) {
      final response = await _apiClient!.get(
        ApiEndpoints.availabilityPublic(slug),
      );
      final data = response['data'] as Map<String, dynamic>;
      return BusinessAvailability.fromJson(data);
    }

    return BusinessAvailability.defaultFor('');
  }

  // ===================== TIME OFF RECORDS =====================

  Future<List<TimeOffRecord>> getTimeOffRecords(
    String businessId, {
    String? staffId,
  }) async {
    if (_storage == null) return [];
    final raw = await _storage!.getString(_timeOffKey(businessId));
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
    if (_storage == null) return;
    final current = await getTimeOffRecords(record.businessId);
    current.add(record);
    final encoded = jsonEncode(current.map((r) => r.toJson()).toList());
    await _storage!.setString(_timeOffKey(record.businessId), encoded);
  }

  Future<void> updateTimeOff(TimeOffRecord updated) async {
    if (_storage == null) return;
    final current = await getTimeOffRecords(updated.businessId);
    final index = current.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      current[index] = updated;
      final encoded = jsonEncode(current.map((r) => r.toJson()).toList());
      await _storage!.setString(_timeOffKey(updated.businessId), encoded);
    }
  }

  Future<void> deleteTimeOff(String businessId, String id) async {
    if (_storage == null) return;
    final current = await getTimeOffRecords(businessId);
    current.removeWhere((r) => r.id == id);
    final encoded = jsonEncode(current.map((r) => r.toJson()).toList());
    await _storage!.setString(_timeOffKey(businessId), encoded);
  }
}
