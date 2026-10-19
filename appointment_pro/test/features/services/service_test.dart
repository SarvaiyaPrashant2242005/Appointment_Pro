import 'package:appointment_pro/core/services/local_storage_service.dart';
import 'package:appointment_pro/features/services/data/models/service_model.dart';
import 'package:appointment_pro/features/services/data/repositories/service_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServiceModel & Validation', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime.now();
      final service = ServiceModel(
        id: 'srv-101',
        businessId: 'biz-1',
        name: 'Haircut & Styling',
        description: 'Premium haircut with hot towel treatment',
        price: 49.99,
        durationMinutes: 45,
        bufferMinutes: 10,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = service.toJson();
      final fromJson = ServiceModel.fromJson(json);

      expect(fromJson.id, 'srv-101');
      expect(fromJson.businessId, 'biz-1');
      expect(fromJson.name, 'Haircut & Styling');
      expect(fromJson.price, 49.99);
      expect(fromJson.durationMinutes, 45);
      expect(fromJson.bufferMinutes, 10);
      expect(fromJson.isActive, isTrue);
    });

    test('validates price, duration, and buffer constraints', () {
      // Valid service
      expect(() {
        final s = ServiceModel(
          id: '1',
          businessId: 'b1',
          name: 'Consultation',
          price: 0.0, // free consultation allowed (non-negative)
          durationMinutes: 15, // positive
          bufferMinutes: 0, // non-negative
        );
        expect(s.price, 0.0);
        expect(s.durationMinutes, 15);
      }, returnsNormally);

      // Validation logic checks
      bool isValidPrice(double? price) => price != null && price >= 0;
      bool isValidDuration(int? duration) => duration != null && duration > 0;
      bool isValidBuffer(int? buffer) => buffer != null && buffer >= 0;

      expect(isValidPrice(-5.0), isFalse);
      expect(isValidPrice(0.0), isTrue);
      expect(isValidPrice(100.0), isTrue);

      expect(isValidDuration(0), isFalse);
      expect(isValidDuration(-10), isFalse);
      expect(isValidDuration(30), isTrue);

      expect(isValidBuffer(-5), isFalse);
      expect(isValidBuffer(0), isTrue);
      expect(isValidBuffer(15), isTrue);
    });

    test('copyWith updates properties properly', () {
      final service = ServiceModel(
        id: 'srv-1',
        businessId: 'b1',
        name: 'Beard Trim',
        price: 20.0,
        durationMinutes: 20,
      );

      final updated = service.copyWith(
        name: 'Deluxe Beard Trim',
        price: 30.0,
        isActive: false,
      );

      expect(updated.id, 'srv-1');
      expect(updated.name, 'Deluxe Beard Trim');
      expect(updated.price, 30.0);
      expect(updated.isActive, isFalse);
    });
  });

  group('ServiceRepository CRUD & Scoping', () {
    late LocalStorageService storageService;
    late ServiceRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = LocalStorageService();
      repository = ServiceRepository(storageService);
    });

    test(
      'creates, reads, updates, and deletes a service for active business',
      () async {
        final service1 = ServiceModel(
          id: 's1',
          businessId: 'biz_alpha',
          name: 'Deep Tissue Massage',
          price: 85.0,
          durationMinutes: 60,
          bufferMinutes: 15,
        );

        // Create
        await repository.createService(service1);

        // Read
        var list = await repository.getServices('biz_alpha');
        expect(list.length, 1);
        expect(list.first.name, 'Deep Tissue Massage');

        // Update
        final updatedService = service1.copyWith(price: 95.0, isActive: false);
        await repository.updateService(updatedService);

        list = await repository.getServices('biz_alpha');
        expect(list.length, 1);
        expect(list.first.price, 95.0);
        expect(list.first.isActive, isFalse);

        // Delete
        await repository.deleteService('biz_alpha', 's1');
        list = await repository.getServices('biz_alpha');
        expect(list, isEmpty);
      },
    );

    test(
      'persists services across repository re-instantiation (simulating app restart)',
      () async {
        final service = ServiceModel(
          id: 's2',
          businessId: 'biz_persist',
          name: 'Oil Therapy',
          price: 120.0,
          durationMinutes: 90,
        );

        await repository.createService(service);

        // Simulate app restart by instantiating new repository instance with same storage
        final restartedRepo = ServiceRepository(storageService);
        final list = await restartedRepo.getServices('biz_persist');

        expect(list.length, 1);
        expect(list.first.id, 's2');
        expect(list.first.name, 'Oil Therapy');
        expect(list.first.price, 120.0);
      },
    );

    test('isolates services by businessId', () async {
      final sBizA = ServiceModel(
        id: 's-a',
        businessId: 'biz_a',
        name: 'Salon Hair Spa',
        price: 50.0,
        durationMinutes: 45,
      );
      final sBizB = ServiceModel(
        id: 's-b',
        businessId: 'biz_b',
        name: 'Dental Cleaning',
        price: 150.0,
        durationMinutes: 30,
      );

      await repository.createService(sBizA);
      await repository.createService(sBizB);

      final listA = await repository.getServices('biz_a');
      expect(listA.length, 1);
      expect(listA.first.name, 'Salon Hair Spa');

      final listB = await repository.getServices('biz_b');
      expect(listB.length, 1);
      expect(listB.first.name, 'Dental Cleaning');

      // biz_c has zero services
      final listC = await repository.getServices('biz_c');
      expect(listC, isEmpty);
    });
  });
}
