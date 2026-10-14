import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return StaffRepository(storage);
});

final staffProvider = AsyncNotifierProvider<StaffController, List<StaffModel>>(
  StaffController.new,
);

class StaffController extends AsyncNotifier<List<StaffModel>> {
  late StaffRepository _repository;

  @override
  Future<List<StaffModel>> build() async {
    _repository = ref.watch(staffRepositoryProvider);
    final businessId = ref.watch(activeBusinessIdProvider);

    if (businessId == null || businessId.isEmpty) {
      return [];
    }

    return _repository.getStaff(businessId);
  }

  Future<void> createStaff(StaffModel staff) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) {
      throw Exception('No active business selected');
    }

    final scopedStaff = staff.copyWith(businessId: businessId);
    final previous = state.asData?.value ?? [];

    try {
      await _repository.createStaff(scopedStaff);
      state = AsyncData([...previous, scopedStaff]);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateStaff(StaffModel updated) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) {
      throw Exception('No active business selected');
    }

    final scopedStaff = updated.copyWith(businessId: businessId);
    final previous = state.asData?.value ?? [];

    try {
      await _repository.updateStaff(scopedStaff);
      final updatedList = previous
          .map((s) => s.id == scopedStaff.id ? scopedStaff : s)
          .toList();
      state = AsyncData(updatedList);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> toggleStatus(String staffId) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) return;

    final previous = state.asData?.value ?? [];

    try {
      await _repository.toggleStaffStatus(businessId, staffId);
      final updatedList = previous.map((s) {
        if (s.id == staffId) {
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

  Future<void> deleteStaff(String staffId) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) return;

    final previous = state.asData?.value ?? [];

    try {
      await _repository.deleteStaff(businessId, staffId);
      final updatedList = previous.where((s) => s.id != staffId).toList();
      state = AsyncData(updatedList);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final staffByIdProvider = Provider.family<StaffModel?, String>((ref, id) {
  final staffList = ref.watch(staffProvider).value ?? [];
  return staffList.where((s) => s.id == id).firstOrNull;
});
