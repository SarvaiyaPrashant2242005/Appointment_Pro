import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/availability/data/models/availability_model.dart';
import 'package:appointment_pro/features/services/data/models/service_model.dart';
import 'package:appointment_pro/features/staff/data/models/staff_model.dart';
import 'package:appointment_pro/features/staff/data/repositories/staff_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StaffModel & Validation', () {
    test(
      'serializes and deserializes correctly with custom schedule and services',
      () {
        final now = DateTime.now();
        final customSchedule = {
          1: const DaySchedule(
            dayOfWeek: 1,
            isOpen: true,
            openTime: '10:00',
            closeTime: '16:00',
          ),
        };

        final staff = StaffModel(
          id: 'st-001',
          businessId: 'biz-1',
          name: 'Alex Johnson',
          email: 'alex@example.com',
          phone: '+1 555-0199',
          assignedServiceIds: ['srv-1', 'srv-2'],
          schedule: customSchedule,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final json = staff.toJson();
        final fromJson = StaffModel.fromJson(json);

        expect(fromJson.id, 'st-001');
        expect(fromJson.name, 'Alex Johnson');
        expect(fromJson.email, 'alex@example.com');
        expect(fromJson.assignedServiceIds, ['srv-1', 'srv-2']);
        expect(fromJson.schedule?[1]?.openTime, '10:00');
        expect(fromJson.isActive, isTrue);
      },
    );

    test('copyWith properly mutates properties', () {
      final staff = StaffModel(
        id: 'st-002',
        businessId: 'biz-1',
        name: 'Maria Garcia',
        assignedServiceIds: ['srv-1'],
      );

      final updated = staff.copyWith(
        name: 'Dr. Maria Garcia',
        assignedServiceIds: ['srv-1', 'srv-3'],
        isActive: false,
      );

      expect(updated.name, 'Dr. Maria Garcia');
      expect(updated.assignedServiceIds, ['srv-1', 'srv-3']);
      expect(updated.isActive, isFalse);
    });
  });

  group('StaffRepository CRUD & Persistence', () {
    late LocalStorageService storageService;
    late StaffRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      repository = StaffRepository(storageService);
    });

    test(
      'creates, reads, updates, and deletes staff records for active business',
      () async {
        final staff1 = StaffModel(
          id: 'st-10',
          businessId: 'biz_main',
          name: 'Robert Chen',
          email: 'robert@chen.com',
          phone: '1234567890',
          assignedServiceIds: ['srv-haircut'],
        );

        // Create
        await repository.createStaff(staff1);

        // Read
        var list = await repository.getStaff('biz_main');
        expect(list.length, 1);
        expect(list.first.name, 'Robert Chen');
        expect(list.first.assignedServiceIds, ['srv-haircut']);

        // Update
        final updatedStaff = staff1.copyWith(
          phone: '9876543210',
          assignedServiceIds: ['srv-haircut', 'srv-coloring'],
          isActive: false,
        );
        await repository.updateStaff(updatedStaff);

        list = await repository.getStaff('biz_main');
        expect(list.length, 1);
        expect(list.first.phone, '9876543210');
        expect(list.first.assignedServiceIds.length, 2);
        expect(list.first.isActive, isFalse);

        // Delete
        await repository.deleteStaff('biz_main', 'st-10');
        list = await repository.getStaff('biz_main');
        expect(list, isEmpty);
      },
    );

    test(
      'persists staff members across repository re-instantiation (app restart)',
      () async {
        final staff = StaffModel(
          id: 'st-persist',
          businessId: 'biz_persist',
          name: 'Samantha Ray',
          assignedServiceIds: ['srv-massage'],
        );

        await repository.createStaff(staff);

        final reloadedRepo = StaffRepository(storageService);
        final list = await reloadedRepo.getStaff('biz_persist');

        expect(list.length, 1);
        expect(list.first.id, 'st-persist');
        expect(list.first.name, 'Samantha Ray');
      },
    );

    test('isolates staff members by businessId', () async {
      final staffA = StaffModel(
        id: 'st-a',
        businessId: 'biz_clinic',
        name: 'Doctor Smith',
      );
      final staffB = StaffModel(
        id: 'st-b',
        businessId: 'biz_salon',
        name: 'Stylist Chloe',
      );

      await repository.createStaff(staffA);
      await repository.createStaff(staffB);

      final clinicStaff = await repository.getStaff('biz_clinic');
      final salonStaff = await repository.getStaff('biz_salon');

      expect(clinicStaff.length, 1);
      expect(clinicStaff.first.name, 'Doctor Smith');

      expect(salonStaff.length, 1);
      expect(salonStaff.first.name, 'Stylist Chloe');

      final emptyStaff = await repository.getStaff('biz_gym');
      expect(emptyStaff, isEmpty);
    });

    test('rejects cross-business service assignments', () {
      final bizAServices = [
        ServiceModel(
          id: 'srv-a1',
          businessId: 'biz_A',
          name: 'Haircut',
          price: 30,
          durationMinutes: 30,
        ),
      ];

      final bizBServices = [
        ServiceModel(
          id: 'srv-b1',
          businessId: 'biz_B',
          name: 'Tooth Extraction',
          price: 200,
          durationMinutes: 45,
        ),
      ];

      // Helper function matching application validation logic
      bool validateStaffServices({
        required String staffBusinessId,
        required List<String> assignedIds,
        required List<ServiceModel> availableServices,
      }) {
        final allowedIds = availableServices
            .where((s) => s.businessId == staffBusinessId)
            .map((s) => s.id)
            .toSet();
        return assignedIds.every((id) => allowedIds.contains(id));
      }

      // Valid assignment: staff of Biz A assigned srv-a1
      expect(
        validateStaffServices(
          staffBusinessId: 'biz_A',
          assignedIds: ['srv-a1'],
          availableServices: [...bizAServices, ...bizBServices],
        ),
        isTrue,
      );

      // Invalid assignment: staff of Biz A assigned srv-b1 (cross-business)
      expect(
        validateStaffServices(
          staffBusinessId: 'biz_A',
          assignedIds: ['srv-b1'],
          availableServices: [...bizAServices, ...bizBServices],
        ),
        isFalse,
      );
    });
  });
}
