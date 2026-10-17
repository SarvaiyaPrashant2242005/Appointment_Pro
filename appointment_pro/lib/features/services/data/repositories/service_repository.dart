import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final ApiClient? _apiClient;
  final LocalStorageService? _storage;

  ServiceRepository(dynamic clientOrStorage, [LocalStorageService? storage])
      : _apiClient = clientOrStorage is ApiClient ? clientOrStorage : null,
        _storage = clientOrStorage is LocalStorageService
            ? clientOrStorage
            : storage;

  static const String _storageKey = 'appointmentpro_services';

  Future<List<ServiceModel>> _loadFromStorage() async {
    final storage = _storage;
    if (storage == null) return [];
    final raw = await storage.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) =>
                ServiceModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToStorage(List<ServiceModel> services) async {
    final storage = _storage;
    if (storage == null) return;
    final encoded = jsonEncode(services.map((s) => s.toJson()).toList());
    await storage.setString(_storageKey, encoded);
  }

  /// Fetch all services for a specific business
  Future<List<ServiceModel>> getServices(
    String businessId, {
    bool? isActive,
  }) async {
    final client = _apiClient;
    if (client != null) {
      final query = <String, dynamic>{
        'businessId': businessId,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await client.get(
        ApiEndpoints.services,
        queryParameters: query,
      );
      final rawData = response['data'];

      if (rawData is List) {
        return rawData
            .map(
              (item) =>
                  ServiceModel.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      return [];
    }

    final all = await _loadFromStorage();
    return all.where((s) {
      if (s.businessId != businessId) return false;
      if (isActive != null && s.isActive != isActive) return false;
      return true;
    }).toList();
  }

  /// Fetch single service by ID
  Future<ServiceModel?> getServiceById(String businessId, String id) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final response = await client.get(ApiEndpoints.serviceById(id));
        final rawData = response['data'];
        if (rawData is Map) {
          return ServiceModel.fromJson(Map<String, dynamic>.from(rawData));
        }
        return null;
      } catch (_) {
        return null;
      }
    }

    final services = await getServices(businessId);
    return services.where((s) => s.id == id).firstOrNull;
  }

  /// Public service lookup for booking page by business slug
  Future<List<ServiceModel>> getPublicServices(String businessSlug) async {
    final client = _apiClient;
    if (client != null) {
      final response = await client.get(
        ApiEndpoints.servicesPublic(businessSlug),
      );
      final rawData = response['data'];

      if (rawData is List) {
        return rawData
            .map(
              (item) =>
                  ServiceModel.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      return [];
    }

    final all = await _loadFromStorage();
    return all.where((s) => s.isActive).toList();
  }

  /// Create a new service under a business
  Future<ServiceModel> createService(ServiceModel service) async {
    final client = _apiClient;
    if (client != null) {
      final body = {
        'businessId': service.businessId,
        'name': service.name,
        if (service.description != null &&
            service.description!.trim().isNotEmpty)
          'description': service.description!.trim(),
        'price': service.price,
        'durationMinutes': service.durationMinutes,
        'bufferMinutes': service.bufferMinutes,
        'isActive': service.isActive,
      };

      final response = await client.post(
        ApiEndpoints.services,
        data: body,
      );
      final data = response['data'] as Map<String, dynamic>;
      return ServiceModel.fromJson(data);
    }

    final all = await _loadFromStorage();
    all.add(service);
    await _saveToStorage(all);
    return service;
  }

  /// Update an existing service
  Future<ServiceModel> updateService(ServiceModel updatedService) async {
    final client = _apiClient;
    if (client != null) {
      final body = {
        'name': updatedService.name,
        'description': updatedService.description,
        'price': updatedService.price,
        'durationMinutes': updatedService.durationMinutes,
        'bufferMinutes': updatedService.bufferMinutes,
        'isActive': updatedService.isActive,
      };

      final response = await client.put(
        ApiEndpoints.serviceById(updatedService.id),
        data: body,
      );
      final data = response['data'] as Map<String, dynamic>;
      return ServiceModel.fromJson(data);
    }

    final all = await _loadFromStorage();
    final index = all.indexWhere(
      (s) =>
          s.id == updatedService.id &&
          s.businessId == updatedService.businessId,
    );
    if (index != -1) {
      all[index] = updatedService;
      await _saveToStorage(all);
    }
    return updatedService;
  }

  /// Toggle active/inactive status
  Future<ServiceModel> toggleStatus(String businessId, String id) async {
    final client = _apiClient;
    if (client != null) {
      final response = await client.patch(ApiEndpoints.serviceToggle(id));
      final data = response['data'] as Map<String, dynamic>;
      return ServiceModel.fromJson(data);
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
    throw Exception('Service not found');
  }

  /// Delete service
  Future<void> deleteService(String businessId, String id) async {
    final client = _apiClient;
    if (client != null) {
      await client.delete(ApiEndpoints.serviceById(id));
      return;
    }

    final all = await _loadFromStorage();
    all.removeWhere((s) => s.id == id && s.businessId == businessId);
    await _saveToStorage(all);
  }
}
