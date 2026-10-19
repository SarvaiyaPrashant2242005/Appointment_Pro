import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_client.dart';
import '../../data/models/business_model.dart';
import '../../data/repositories/business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BusinessRepository(apiClient);
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

  /// Manually re-fetches businesses from server
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getBusinesses());
  }

  Future<void> createBusiness(BusinessModel business) async {
    final previous = state.asData?.value ?? [];
    state = const AsyncLoading();

    try {
      final updated = await _repository.createBusiness(business);
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateBusiness(BusinessModel business) async {
    final previous = state.asData?.value ?? [];
    state = const AsyncLoading();

    try {
      final updated = await _repository.updateBusiness(business);
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> setActiveBusiness(String id) async {
    final previous = state.asData?.value ?? [];
    state = const AsyncLoading();

    try {
      final updated = await _repository.setActiveBusiness(id);
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> deleteBusiness(String id) async {
    final previous = state.asData?.value ?? [];
    state = const AsyncLoading();

    try {
      final updated = await _repository.deleteBusiness(id);
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

final activeBusinessIdProvider = Provider<String?>((ref) {
  return ref.watch(activeBusinessProvider)?.id;
});
