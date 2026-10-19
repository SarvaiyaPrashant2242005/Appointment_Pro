import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/availability/data/models/availability_model.dart';
import 'package:appointment_pro/features/availability/data/repositories/availability_repository.dart';
import 'package:appointment_pro/features/services/data/models/service_model.dart';
import 'package:appointment_pro/features/services/data/repositories/service_repository.dart';
import 'package:appointment_pro/features/staff/data/models/staff_model.dart';
import 'package:appointment_pro/features/staff/data/repositories/staff_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Business Isolation & Persistence Test', () {
    late LocalStorageService storageService;
    late ServiceRepository serviceRepo;
    late StaffRepository staffRepo;
    late AvailabilityRepository availRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      serviceRepo = ServiceRepository(storageService);
      staffRepo = StaffRepository(storageService);
      availRepo = AvailabilityRepository(storageService);
    });

    test(
      'Two distinct businesses maintain completely isolated records across services, staff, and availability',
      () async {
        const biz1Id = 'biz_salon_1';
        const biz2Id = 'biz_dental_2';

        // 1. Setup Services for Business 1
        await serviceRepo.createService(
          ServiceModel(
            id: 's-salon-1',
            businessId: biz1Id,
            name: 'Classic Haircut',
            price: 35.0,
            durationMinutes: 30,
          ),
        );
        await serviceRepo.createService(
          ServiceModel(
            id: 's-salon-2',
            businessId: biz1Id,
            name: 'Hair Coloring',
            price: 80.0,
            durationMinutes: 90,
          ),
        );

        // 2. Setup Services for Business 2
        await serviceRepo.createService(
          ServiceModel(
            id: 's-dental-1',
            businessId: biz2Id,
            name: 'Teeth Whitening',
            price: 250.0,
            durationMinutes: 60,
          ),
        );

        // 3. Setup Staff for Business 1
        await staffRepo.createStaff(
          StaffModel(
            id: 'st-salon-1',
            businessId: biz1Id,
            name: 'Lisa Hairstylist',
            assignedServiceIds: ['s-salon-1', 's-salon-2'],
          ),
        );

        // 4. Setup Staff for Business 2
        await staffRepo.createStaff(
          StaffModel(
            id: 'st-dental-1',
            businessId: biz2Id,
            name: 'Dr. Gregory House',
            assignedServiceIds: ['s-dental-1'],
          ),
        );

        // 5. Setup Availability & Holidays for Business 1
        final avail1 = (await availRepo.getBusinessAvailability(biz1Id))
            .copyWith(
              weeklySchedule: {
                1: const DaySchedule(
                  dayOfWeek: 1,
                  isOpen: true,
                  openTime: '10:00',
                  closeTime: '20:00',
                ),
              },
            );
        await availRepo.saveBusinessAvailability(avail1);
        await availRepo.addTimeOff(
          TimeOffRecord(
            id: 'hol-salon-1',
            businessId: biz1Id,
            title: 'Salon Renovation Day',
            startDate: DateTime(2027, 4, 1),
            endDate: DateTime(2027, 4, 2),
          ),
        );

        // 6. Setup Availability & Holidays for Business 2
        final avail2 = (await availRepo.getBusinessAvailability(biz2Id))
            .copyWith(
              weeklySchedule: {
                1: const DaySchedule(
                  dayOfWeek: 1,
                  isOpen: true,
                  openTime: '08:00',
                  closeTime: '16:00',
                ),
              },
            );
        await availRepo.saveBusinessAvailability(avail2);
        await availRepo.addTimeOff(
          TimeOffRecord(
            id: 'hol-dental-1',
            businessId: biz2Id,
            title: 'Dental Conference',
            startDate: DateTime(2027, 5, 10),
            endDate: DateTime(2027, 5, 12),
          ),
        );

        // --- VERIFY BUSINESS 1 SCOPE ---
        final b1Services = await serviceRepo.getServices(biz1Id);
        final b1Staff = await staffRepo.getStaff(biz1Id);
        final b1Avail = await availRepo.getBusinessAvailability(biz1Id);
        final b1Holidays = await availRepo.getTimeOffRecords(biz1Id);

        expect(
          b1Services.map((s) => s.name).toList(),
          containsAll(['Classic Haircut', 'Hair Coloring']),
        );
        expect(b1Services.any((s) => s.name == 'Teeth Whitening'), isFalse);

        expect(b1Staff.map((s) => s.name).toList(), ['Lisa Hairstylist']);
        expect(b1Staff.any((s) => s.name == 'Dr. Gregory House'), isFalse);

        expect(b1Avail.weeklySchedule[1]!.openTime, '10:00');
        expect(b1Holidays.map((h) => h.title).toList(), [
          'Salon Renovation Day',
        ]);

        // --- SWITCH TO BUSINESS 2 AND VERIFY SCOPE ---
        final b2Services = await serviceRepo.getServices(biz2Id);
        final b2Staff = await staffRepo.getStaff(biz2Id);
        final b2Avail = await availRepo.getBusinessAvailability(biz2Id);
        final b2Holidays = await availRepo.getTimeOffRecords(biz2Id);

        expect(b2Services.map((s) => s.name).toList(), ['Teeth Whitening']);
        expect(b2Services.any((s) => s.name == 'Classic Haircut'), isFalse);

        expect(b2Staff.map((s) => s.name).toList(), ['Dr. Gregory House']);
        expect(b2Staff.any((s) => s.name == 'Lisa Hairstylist'), isFalse);

        expect(b2Avail.weeklySchedule[1]!.openTime, '08:00');
        expect(b2Holidays.map((h) => h.title).toList(), ['Dental Conference']);

        // --- VERIFY PERSISTENCE AFTER RESTART ---
        final restartedServiceRepo = ServiceRepository(storageService);
        final restartedStaffRepo = StaffRepository(storageService);
        final restartedAvailRepo = AvailabilityRepository(storageService);

        final restartedB1Services = await restartedServiceRepo.getServices(
          biz1Id,
        );
        final restartedB2Staff = await restartedStaffRepo.getStaff(biz2Id);
        final restartedB1Avail = await restartedAvailRepo
            .getBusinessAvailability(biz1Id);

        expect(restartedB1Services.length, 2);
        expect(restartedB2Staff.first.name, 'Dr. Gregory House');
        expect(restartedB1Avail.weeklySchedule[1]!.openTime, '10:00');
      },
    );
  });
}
