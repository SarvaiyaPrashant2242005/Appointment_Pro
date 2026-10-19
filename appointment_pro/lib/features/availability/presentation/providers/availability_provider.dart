import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/availability_model.dart';
import '../../data/repositories/availability_repository.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(localStorageServiceProvider);
  return AvailabilityRepository(apiClient, storage);
});

final availabilityProvider =
    AsyncNotifierProvider<AvailabilityController, BusinessAvailability>(
      AvailabilityController.new,
    );

class AvailabilityController extends AsyncNotifier<BusinessAvailability> {
  late AvailabilityRepository _repository;

  @override
  Future<BusinessAvailability> build() async {
    _repository = ref.watch(availabilityRepositoryProvider);
    final businessId = ref.watch(activeBusinessIdProvider);

    if (businessId == null || businessId.isEmpty) {
      return BusinessAvailability.defaultFor('');
    }

    return _repository.getBusinessAvailability(businessId);
  }

  Future<void> updateDaySchedule(DaySchedule schedule) async {
    final current = state.asData?.value;
    if (current == null) return;

    final updatedMap = Map<int, DaySchedule>.from(current.weeklySchedule);
    updatedMap[schedule.dayOfWeek] = schedule;

    final updatedAvailability = current.copyWith(weeklySchedule: updatedMap);

    try {
      final saved =
          await _repository.saveBusinessAvailability(updatedAvailability);
      state = AsyncData(saved);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> toggleDay(int dayOfWeek, bool isOpen) async {
    final current = state.asData?.value;
    if (current == null) return;

    final day = current.weeklySchedule[dayOfWeek];
    if (day == null) return;

    await updateDaySchedule(day.copyWith(isOpen: isOpen));
  }

  Future<void> updateDayHours(
    int dayOfWeek, {
    required String openTime,
    required String closeTime,
  }) async {
    final current = state.asData?.value;
    if (current == null) return;

    final day = current.weeklySchedule[dayOfWeek];
    if (day == null) return;

    final newSchedule = day.copyWith(openTime: openTime, closeTime: closeTime);

    final breakError = newSchedule.validateBreaks();
    if (breakError != null) {
      throw Exception(breakError);
    }

    await updateDaySchedule(newSchedule);
  }

  Future<void> addBreak(int dayOfWeek, TimeRange newBreak) async {
    final current = state.asData?.value;
    if (current == null) return;

    final day = current.weeklySchedule[dayOfWeek];
    if (day == null) return;

    final updatedBreaks = List<TimeRange>.from(day.breaks)..add(newBreak);
    // Sort breaks by start time
    updatedBreaks.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    final newSchedule = day.copyWith(breaks: updatedBreaks);
    final breakError = newSchedule.validateBreaks();
    if (breakError != null) {
      throw Exception(breakError);
    }

    await updateDaySchedule(newSchedule);
  }

  Future<void> removeBreak(int dayOfWeek, int breakIndex) async {
    final current = state.asData?.value;
    if (current == null) return;

    final day = current.weeklySchedule[dayOfWeek];
    if (day == null) return;

    if (breakIndex < 0 || breakIndex >= day.breaks.length) return;

    final updatedBreaks = List<TimeRange>.from(day.breaks)
      ..removeAt(breakIndex);
    await updateDaySchedule(day.copyWith(breaks: updatedBreaks));
  }

  Future<void> applyScheduleToDays(
    int sourceDayOfWeek, {
    bool openDaysOnly = true,
  }) async {
    final current = state.asData?.value;
    if (current == null) return;

    final sourceDay = current.weeklySchedule[sourceDayOfWeek];
    if (sourceDay == null) return;

    final updatedMap = Map<int, DaySchedule>.from(current.weeklySchedule);

    for (final entry in current.weeklySchedule.entries) {
      final dayOfWeek = entry.key;
      final schedule = entry.value;

      if (dayOfWeek == sourceDayOfWeek) continue;

      if (!openDaysOnly || schedule.isOpen) {
        updatedMap[dayOfWeek] = schedule.copyWith(
          isOpen: openDaysOnly ? schedule.isOpen : true,
          openTime: sourceDay.openTime,
          closeTime: sourceDay.closeTime,
          breaks: List<TimeRange>.from(sourceDay.breaks),
        );
      }
    }

    final updatedAvailability = current.copyWith(weeklySchedule: updatedMap);

    try {
      final saved =
          await _repository.saveBusinessAvailability(updatedAvailability);
      state = AsyncData(saved);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final timeOffListProvider =
    AsyncNotifierProvider<TimeOffListController, List<TimeOffRecord>>(
      TimeOffListController.new,
    );

class TimeOffListController extends AsyncNotifier<List<TimeOffRecord>> {
  late AvailabilityRepository _repository;

  @override
  Future<List<TimeOffRecord>> build() async {
    _repository = ref.watch(availabilityRepositoryProvider);
    final businessId = ref.watch(activeBusinessIdProvider);

    if (businessId == null || businessId.isEmpty) {
      return [];
    }

    return _repository.getTimeOffRecords(businessId);
  }

  Future<void> addTimeOff(TimeOffRecord record) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) {
      throw Exception('No active business selected');
    }

    final scoped = record.copyWith(businessId: businessId);
    final previous = state.asData?.value ?? [];

    try {
      await _repository.addTimeOff(scoped);
      state = AsyncData([...previous, scoped]);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateTimeOff(TimeOffRecord record) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) {
      throw Exception('No active business selected');
    }

    final scoped = record.copyWith(businessId: businessId);
    final previous = state.asData?.value ?? [];

    try {
      await _repository.updateTimeOff(scoped);
      final updated = previous
          .map((r) => r.id == scoped.id ? scoped : r)
          .toList();
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> deleteTimeOff(String id) async {
    final businessId = ref.read(activeBusinessIdProvider);
    if (businessId == null) return;

    final previous = state.asData?.value ?? [];

    try {
      await _repository.deleteTimeOff(businessId, id);
      final updated = previous.where((r) => r.id != id).toList();
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}
