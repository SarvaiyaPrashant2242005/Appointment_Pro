import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ServiceRepository(storage);
});

final servicesProvider =
    AsyncNotifierProvider<ServicesController, List<ServiceModel>>(
      ServicesController.new,
    );

class ServicesController extends AsyncNotifier<List<ServiceModel>> {
  late ServiceRepository _repository;

  @override
  Future<List<ServiceModel>> build() async {
    _repository = ref.watch(serviceRepositoryProvider);
    final businessId = ref.watch(activeBusinessIdProvider);

    if (businessId == null || businessId.isEmpty) {
      return [];
    }

    return _repository.getServices(businessId);
  }

  Future<void> createService(ServiceModel service) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) {
      throw Exception('No active business selected');
    }

    final scopedService = service.copyWith(businessId: businessId);
    final previous = state.asData?.value ?? [];

    try {
      await _repository.createService(scopedService);
      state = AsyncData([...previous, scopedService]);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateService(ServiceModel updated) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) {
      throw Exception('No active business selected');
    }

    final scopedService = updated.copyWith(businessId: businessId);
    final previous = state.asData?.value ?? [];

    try {
      await _repository.updateService(scopedService);
      final updatedList = previous
          .map((s) => s.id == scopedService.id ? scopedService : s)
          .toList();
      state = AsyncData(updatedList);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> toggleStatus(String serviceId) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) return;

    final previous = state.asData?.value ?? [];

    try {
      await _repository.toggleStatus(businessId, serviceId);
      final updatedList = previous.map((s) {
        if (s.id == serviceId) {
          return s.copyWith(isActive: !s.isActive, updatedAt: DateTime.now());
        }
        return s;
      }).toList();
      state = AsyncData(updatedList);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) return;

    final previous = state.asData?.value ?? [];

    try {
      await _repository.deleteService(businessId, serviceId);
      final updatedList = previous.where((s) => s.id != serviceId).toList();
      state = AsyncData(updatedList);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final serviceByIdProvider = Provider.family<ServiceModel?, String>((ref, id) {
  final services = ref.watch(servicesProvider).value ?? [];
  return services.where((s) => s.id == id).firstOrNull;
});
