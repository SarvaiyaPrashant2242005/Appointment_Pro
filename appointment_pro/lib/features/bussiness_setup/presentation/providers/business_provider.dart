import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../data/models/business_model.dart';
import '../../data/repositories/business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(LocalStorageService());
});

final businessProvider =
    AsyncNotifierProvider<BusinessController, List<BusinessModel>>(
      BusinessController.new,
    );

class BusinessController extends AsyncNotifier<List<BusinessModel>> {
  late final BusinessRepository _repository;

  @override
  Future<List<BusinessModel>> build() async {
    _repository = ref.read(businessRepositoryProvider);
    return _repository.getBusinesses();
  }

  Future<void> createBusiness(BusinessModel business) async {
    final previous = state.asData?.value ?? [];

    try {
      final updated = await _repository.createBusiness(business);
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> setActiveBusiness(String id) async {
    final previous = state.asData?.value ?? [];

    try {
      final updated = await _repository.setActiveBusiness(id);
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final activeBusinessProvider = Provider<BusinessModel?>((ref) {
  final businesses = ref.watch(businessProvider).value ?? [];
  return businesses.where((b) => b.isActive).firstOrNull ??
      businesses.firstOrNull;
});
