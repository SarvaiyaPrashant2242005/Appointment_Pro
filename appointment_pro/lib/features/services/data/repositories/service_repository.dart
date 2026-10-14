import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final LocalStorageService _storage;

  ServiceRepository(this._storage);

  static const String _key = 'appointmentpro_services';

  Future<List<ServiceModel>> _loadAll() async {
    final raw = await _storage.getString(_key);
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

  Future<void> _saveAll(List<ServiceModel> services) async {
    final encoded = jsonEncode(services.map((s) => s.toJson()).toList());
    await _storage.setString(_key, encoded);
  }

  Future<List<ServiceModel>> getServices(String businessId) async {
    final all = await _loadAll();
    return all.where((s) => s.businessId == businessId).toList();
  }

  Future<ServiceModel?> getServiceById(String businessId, String id) async {
    final services = await getServices(businessId);
    return services.where((s) => s.id == id).firstOrNull;
  }

  Future<void> createService(ServiceModel service) async {
    final all = await _loadAll();
    all.add(service);
    await _saveAll(all);
  }

  Future<void> updateService(ServiceModel updatedService) async {
    final all = await _loadAll();
    final index = all.indexWhere(
      (s) =>
          s.id == updatedService.id &&
          s.businessId == updatedService.businessId,
    );
    if (index != -1) {
      all[index] = updatedService;
      await _saveAll(all);
    }
  }

  Future<void> toggleStatus(String businessId, String id) async {
    final all = await _loadAll();
    final index = all.indexWhere(
      (s) => s.id == id && s.businessId == businessId,
    );
    if (index != -1) {
      all[index] = all[index].copyWith(
        isActive: !all[index].isActive,
        updatedAt: DateTime.now(),
      );
      await _saveAll(all);
    }
  }

  Future<void> deleteService(String businessId, String id) async {
    final all = await _loadAll();
    all.removeWhere((s) => s.id == id && s.businessId == businessId);
    await _saveAll(all);
  }
}
