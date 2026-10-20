import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/services/local_storage_service.dart';
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
  BusinessRepository get _repo => ref.read(businessRepositoryProvider);

  @override
  Future<List<BusinessModel>> build() async {
    final storage = ref.read(localStorageServiceProvider);
    final isLoggedIn = await storage.isLoggedIn();
    if (!isLoggedIn) {
      return [];
    }
    return _repo.getBusinesses();
  }

  /// Explicitly re-fetches businesses from server, directly sets state = AsyncData,
  /// and returns the fresh list. Used on login, OTP verification, or splash navigation.
  Future<List<BusinessModel>> fetchFresh() async {
    state = const AsyncLoading();
    try {
      final list = await _repo.getBusinesses();
      state = AsyncData(list);
      return list;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Manually re-fetches businesses from server
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getBusinesses());
  }

  /// Clears businesses to empty list without network calls (used on logout)
  void clear() {
    state = const AsyncData([]);
  }

  Future<void> createBusiness(BusinessModel business) async {
    final previous = state.asData?.value ?? [];
    state = const AsyncLoading();

    try {
      final updated = await _repo.createBusiness(business);
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
      final updated = await _repo.updateBusiness(business);
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
      final updated = await _repo.setActiveBusiness(id);
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
      final updated = await _repo.deleteBusiness(id);
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
