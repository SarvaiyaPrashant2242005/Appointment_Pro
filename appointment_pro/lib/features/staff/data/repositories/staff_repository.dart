import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final ApiClient? _apiClient;
  final LocalStorageService? _storage;

  StaffRepository(dynamic clientOrStorage, [LocalStorageService? storage])
      : _apiClient = clientOrStorage is ApiClient ? clientOrStorage : null,
        _storage = clientOrStorage is LocalStorageService
            ? clientOrStorage
            : storage;

  static const String _storageKey = 'appointmentpro_staff';

  Future<List<StaffModel>> _loadFromStorage() async {
    final storage = _storage;
    if (storage == null) return [];
    final raw = await storage.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) =>
                StaffModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToStorage(List<StaffModel> list) async {
    final storage = _storage;
    if (storage == null) return;
    final encoded = jsonEncode(list.map((s) => s.toJson()).toList());
    await storage.setString(_storageKey, encoded);
  }

  /// Fetch staff team for a business
  Future<List<StaffModel>> getStaff(
    String businessId, {
    String? serviceId,
    bool? isActive,
  }) async {
    final client = _apiClient;
    if (client != null) {
      final query = <String, dynamic>{
        'businessId': businessId,
        if (serviceId != null) 'serviceId': serviceId,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await client.get(
        ApiEndpoints.staff,
        queryParameters: query,
      );
      final rawData = response['data'];

      if (rawData is List) {
        return rawData
            .map(
              (item) =>
                  StaffModel.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      return [];
    }

    final all = await _loadFromStorage();
    return all.where((s) {
      if (s.businessId != businessId) return false;
      if (isActive != null && s.isActive != isActive) return false;
      if (serviceId != null && !s.assignedServiceIds.contains(serviceId)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Fetch single staff member by ID
  Future<StaffModel?> getStaffById(String businessId, String id) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final response = await client.get(ApiEndpoints.staffById(id));
        final rawData = response['data'];
        if (rawData is Map) {
          return StaffModel.fromJson(Map<String, dynamic>.from(rawData));
        }
        return null;
      } catch (_) {
        return null;
      }
    }

    final list = await getStaff(businessId);
    return list.where((s) => s.id == id).firstOrNull;
  }

  /// Public staff lookup for customer booking
  Future<List<StaffModel>> getPublicStaff(
    String businessSlug, {
    String? serviceId,
  }) async {
    final client = _apiClient;
    if (client != null) {
      final query = <String, dynamic>{
        if (serviceId != null) 'serviceId': serviceId,
      };

      final response = await client.get(
        ApiEndpoints.staffPublic(businessSlug),
        queryParameters: query,
      );
      final rawData = response['data'];

      if (rawData is List) {
        return rawData
            .map(
              (item) =>
                  StaffModel.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      return [];
    }

    final all = await _loadFromStorage();
    return all.where((s) => s.isActive).toList();
  }

  /// Create a new staff member (supports avatar upload)
  Future<StaffModel> createStaff(StaffModel staff) async {
    final client = _apiClient;
    if (client != null) {
      final avatarPath = staff.avatarPath;
      final hasLocalAvatar =
          avatarPath != null &&
          !avatarPath.startsWith('http://') &&
          !avatarPath.startsWith('https://') &&
          !avatarPath.startsWith('/') &&
          File(avatarPath).existsSync();

      if (hasLocalAvatar) {
        final fileName = avatarPath.split(RegExp(r'[/\\]')).last;
        final formData = FormData.fromMap({
          'businessId': staff.businessId,
          'name': staff.name,
          if (staff.email != null && staff.email!.trim().isNotEmpty)
            'email': staff.email!.trim(),
          if (staff.phone != null && staff.phone!.trim().isNotEmpty)
            'phone': staff.phone!.trim(),
          'isActive': staff.isActive,
          'assignedServiceIds': jsonEncode(staff.assignedServiceIds),
          if (staff.schedule != null)
            'schedule': jsonEncode(
              staff.schedule!.map((k, v) => MapEntry(k.toString(), v.toJson())),
            ),
          'avatar': await MultipartFile.fromFile(avatarPath, filename: fileName),
        });

        final response =
            await client.post(ApiEndpoints.staff, data: formData);
        final data = response['data'] as Map<String, dynamic>;
        return StaffModel.fromJson(data);
      } else {
        final body = {
          'businessId': staff.businessId,
          'name': staff.name,
          if (staff.email != null && staff.email!.trim().isNotEmpty)
            'email': staff.email!.trim(),
          if (staff.phone != null && staff.phone!.trim().isNotEmpty)
            'phone': staff.phone!.trim(),
          'isActive': staff.isActive,
          'assignedServiceIds': staff.assignedServiceIds,
          if (staff.schedule != null)
            'schedule': staff.schedule!.map(
              (k, v) => MapEntry(k.toString(), v.toJson()),
            ),
        };

        final response = await client.post(ApiEndpoints.staff, data: body);
        final data = response['data'] as Map<String, dynamic>;
        return StaffModel.fromJson(data);
      }
    }

    final all = await _loadFromStorage();
    all.add(staff);
    await _saveToStorage(all);
    return staff;
  }

  /// Update an existing staff member (supports avatar update)
  Future<StaffModel> updateStaff(StaffModel staff) async {
    final client = _apiClient;
    if (client != null) {
      final avatarPath = staff.avatarPath;
      final isNewLocalAvatar =
          avatarPath != null &&
          !avatarPath.startsWith('http://') &&
          !avatarPath.startsWith('https://') &&
          !avatarPath.startsWith('/') &&
          File(avatarPath).existsSync();

      final endpoint = ApiEndpoints.staffById(staff.id);

      if (isNewLocalAvatar) {
        final fileName = avatarPath.split(RegExp(r'[/\\]')).last;
        final formData = FormData.fromMap({
          'name': staff.name,
          if (staff.email != null && staff.email!.trim().isNotEmpty)
            'email': staff.email!.trim(),
          if (staff.phone != null && staff.phone!.trim().isNotEmpty)
            'phone': staff.phone!.trim(),
          'isActive': staff.isActive,
          'assignedServiceIds': jsonEncode(staff.assignedServiceIds),
          if (staff.schedule != null)
            'schedule': jsonEncode(
              staff.schedule!.map((k, v) => MapEntry(k.toString(), v.toJson())),
            ),
          'avatar': await MultipartFile.fromFile(avatarPath, filename: fileName),
        });

        final response = await client.put(endpoint, data: formData);
        final data = response['data'] as Map<String, dynamic>;
        return StaffModel.fromJson(data);
      } else {
        final body = {
          'name': staff.name,
          if (staff.email != null) 'email': staff.email!.trim(),
          if (staff.phone != null) 'phone': staff.phone!.trim(),
          'isActive': staff.isActive,
          'assignedServiceIds': staff.assignedServiceIds,
          if (staff.schedule != null)
            'schedule': staff.schedule!.map(
              (k, v) => MapEntry(k.toString(), v.toJson()),
            ),
        };

        final response = await client.put(endpoint, data: body);
        final data = response['data'] as Map<String, dynamic>;
        return StaffModel.fromJson(data);
      }
    }

    final all = await _loadFromStorage();
    final index = all.indexWhere(
      (s) => s.id == staff.id && s.businessId == staff.businessId,
    );
    if (index != -1) {
      all[index] = staff;
      await _saveToStorage(all);
    }
    return staff;
  }

  /// Toggle active/inactive status
  Future<StaffModel> toggleStaffStatus(String businessId, String id) async {
    final client = _apiClient;
    if (client != null) {
      final response = await client.patch(ApiEndpoints.staffToggle(id));
      final data = response['data'] as Map<String, dynamic>;
      return StaffModel.fromJson(data);
    }

    final all = await _loadFromStorage();
    final index = all.indexWhere(
      (s) => s.id == id && s.businessId == businessId,
    );
    if (index != -1) {
      all[index] = all[index].copyWith(
        isActive: !all[index].isActive,
        updatedAt: DateTime.now(),
      );
      await _saveToStorage(all);
      return all[index];
    }
    throw Exception('Staff member not found');
  }

  /// Delete staff member
  Future<void> deleteStaff(String businessId, String id) async {
    final client = _apiClient;
    if (client != null) {
      await client.delete(ApiEndpoints.staffById(id));
      return;
    }

    final all = await _loadFromStorage();
    all.removeWhere((s) => s.id == id && s.businessId == businessId);
    await _saveToStorage(all);
  }
}
