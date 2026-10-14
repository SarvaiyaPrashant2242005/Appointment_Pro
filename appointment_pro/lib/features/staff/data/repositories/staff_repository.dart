import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final LocalStorageService _storage;

  StaffRepository(this._storage);

  static const String _key = 'appointmentpro_staff';

  Future<List<StaffModel>> _loadAll() async {
    final raw = await _storage.getString(_key);
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

  Future<void> _saveAll(List<StaffModel> list) async {
    final encoded = jsonEncode(list.map((s) => s.toJson()).toList());
    await _storage.setString(_key, encoded);
  }

  Future<List<StaffModel>> getStaff(String businessId) async {
    final all = await _loadAll();
    return all.where((s) => s.businessId == businessId).toList();
  }

  Future<StaffModel?> getStaffById(String businessId, String id) async {
    final list = await getStaff(businessId);
    return list.where((s) => s.id == id).firstOrNull;
  }

  Future<void> createStaff(StaffModel staff) async {
    final all = await _loadAll();
    all.add(staff);
    await _saveAll(all);
  }

  Future<void> updateStaff(StaffModel updated) async {
    final all = await _loadAll();
    final index = all.indexWhere(
      (s) => s.id == updated.id && s.businessId == updated.businessId,
    );
    if (index != -1) {
      all[index] = updated;
      await _saveAll(all);
    }
  }

  Future<void> toggleStaffStatus(String businessId, String id) async {
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

  Future<void> deleteStaff(String businessId, String id) async {
    final all = await _loadAll();
    all.removeWhere((s) => s.id == id && s.businessId == businessId);
    await _saveAll(all);
  }
}
