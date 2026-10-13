import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../models/business_model.dart';

class BusinessRepository {
  BusinessRepository(this._storage);

  final LocalStorageService _storage;

  static const _key = 'appointmentpro_businesses';

  Future<List<BusinessModel>> getBusinesses() async {
    final json = await _storage.getString(_key);

    if (json == null || json.isEmpty) return [];

    final decoded = jsonDecode(json) as List<dynamic>;

    return decoded
        .map(
          (item) =>
              BusinessModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> _save(List<BusinessModel> businesses) async {
    await _storage.setString(
      _key,
      jsonEncode(businesses.map((b) => b.toJson()).toList()),
    );
  }

  Future<List<BusinessModel>> createBusiness(BusinessModel business) async {
    final businesses = await getBusinesses();

    final newBusiness = business.copyWith(isActive: businesses.isEmpty);

    final updated = [...businesses, newBusiness];
    await _save(updated);
    return updated;
  }

  Future<List<BusinessModel>> setActiveBusiness(String id) async {
    final businesses = await getBusinesses();

    final updated = businesses
        .map((b) => b.copyWith(isActive: b.id == id))
        .toList();

    await _save(updated);
    return updated;
  }
}
