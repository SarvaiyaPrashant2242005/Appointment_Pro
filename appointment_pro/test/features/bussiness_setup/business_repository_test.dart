import 'package:appointment_pro/core/constants/api_endpoints.dart';
import 'package:appointment_pro/core/services/api_client.dart';
import 'package:appointment_pro/features/bussiness_setup/data/models/business_model.dart';
import 'package:appointment_pro/features/bussiness_setup/data/repositories/business_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MockApiClient implements ApiClient {
  String? lastGetPath;
  String? lastPostPath;
  dynamic lastPostData;
  String? lastPutPath;
  dynamic lastPutData;
  String? lastPatchPath;
  dynamic lastPatchData;
  String? lastDeletePath;

  Map<String, dynamic> getResponse = {'data': []};
  Map<String, dynamic> postResponse = {'data': {}};
  Map<String, dynamic> putResponse = {'data': {}};
  Map<String, dynamic> patchResponse = {'data': {}};
  Map<String, dynamic> deleteResponse = {'data': {}};

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters, dynamic options}) async {
    lastGetPath = path;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, dynamic options}) async {
    lastPostPath = path;
    lastPostData = data;
    return postResponse;
  }

  @override
  Future<Map<String, dynamic>> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, dynamic options}) async {
    lastPutPath = path;
    lastPutData = data;
    return putResponse;
  }

  @override
  Future<Map<String, dynamic>> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, dynamic options}) async {
    lastPatchPath = path;
    lastPatchData = data;
    return patchResponse;
  }

  @override
  Future<Map<String, dynamic>> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, dynamic options}) async {
    lastDeletePath = path;
    return deleteResponse;
  }
}

void main() {
  group('BusinessModel Serialization & Helpers', () {
    test('parses from database snake_case json', () {
      final json = {
        'id': 'b123',
        'owner_id': 'u456',
        'name': 'Glow Spa',
        'slug': 'glow-spa-1234',
        'type': 'Salon / Beauty',
        'other_type': null,
        'logo_url': '/uploads/logos/logo.png',
        'email': 'contact@glowspa.com',
        'country_code': '+91',
        'phone': '9876543210',
        'currency': 'INR',
        'timezone': 'Asia/Kolkata',
        'is_active': true,
        'created_at': '2026-03-01T10:00:00.000Z',
      };

      final model = BusinessModel.fromJson(json);

      expect(model.id, 'b123');
      expect(model.ownerId, 'u456');
      expect(model.name, 'Glow Spa');
      expect(model.slug, 'glow-spa-1234');
      expect(model.type, 'Salon / Beauty');
      expect(model.logoPath, '/uploads/logos/logo.png');
      expect(model.email, 'contact@glowspa.com');
      expect(model.countryCode, '+91');
      expect(model.phone, '9876543210');
      expect(model.currency, 'INR');
      expect(model.timezone, 'Asia/Kolkata');
      expect(model.isActive, isTrue);
      expect(model.fullLogoUrl, contains('/uploads/logos/logo.png'));
    });

    test('toApiMap serializes payload matching backend validation', () {
      final model = BusinessModel(
        id: 'temp_id',
        name: 'Apex Dental',
        type: 'Healthcare / Hospital',
        email: 'info@apexdental.com',
        phone: '1234567890',
        createdAt: DateTime.now(),
      );

      final map = model.toApiMap();

      expect(map['name'], 'Apex Dental');
      expect(map['type'], 'Healthcare / Hospital');
      expect(map['email'], 'info@apexdental.com');
      expect(map['countryCode'], '+91');
      expect(map['phone'], '1234567890');
      expect(map.containsKey('id'), isFalse);
    });
  });

  group('BusinessRepository API CRUD', () {
    late MockApiClient mockApi;
    late BusinessRepository repo;

    setUp(() {
      mockApi = MockApiClient();
      repo = BusinessRepository(mockApi);
    });

    test('getBusinesses fetches from /businesses endpoint', () async {
      mockApi.getResponse = {
        'data': [
          {
            'id': 'b1',
            'name': 'Biz One',
            'type': 'Salon',
            'is_active': true,
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ],
      };

      final list = await repo.getBusinesses();

      expect(mockApi.lastGetPath, ApiEndpoints.businesses);
      expect(list.length, 1);
      expect(list.first.name, 'Biz One');
      expect(list.first.isActive, isTrue);
    });

    test('createBusiness calls POST /businesses and returns updated list', () async {
      mockApi.getResponse = {
        'data': [
          {
            'id': 'b_created',
            'name': 'New Biz',
            'type': 'Corporate',
            'is_active': true,
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ],
      };

      final newBiz = BusinessModel(
        id: '',
        name: 'New Biz',
        type: 'Corporate',
        createdAt: DateTime.now(),
      );

      final list = await repo.createBusiness(newBiz);

      expect(mockApi.lastPostPath, ApiEndpoints.businesses);
      expect(list.length, 1);
      expect(list.first.name, 'New Biz');
    });

    test('setActiveBusiness calls PATCH /businesses/:id/activate', () async {
      mockApi.getResponse = {
        'data': [
          {
            'id': 'b2',
            'name': 'Biz Two',
            'type': 'Gym',
            'is_active': true,
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ],
      };

      final list = await repo.setActiveBusiness('b2');

      expect(mockApi.lastPatchPath, ApiEndpoints.businessActivate('b2'));
      expect(list.first.id, 'b2');
      expect(list.first.isActive, isTrue);
    });

    test('deleteBusiness calls DELETE /businesses/:id', () async {
      mockApi.getResponse = {'data': []};

      final list = await repo.deleteBusiness('b_delete');

      expect(mockApi.lastDeletePath, ApiEndpoints.businessById('b_delete'));
      expect(list.isEmpty, isTrue);
    });
  });
}
