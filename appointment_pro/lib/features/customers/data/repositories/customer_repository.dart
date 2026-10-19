import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final ApiClient? _apiClient;
  final LocalStorageService? _storage;

  CustomerRepository(dynamic clientOrStorage, [LocalStorageService? storage])
      : _apiClient = clientOrStorage is ApiClient ? clientOrStorage : null,
        _storage = clientOrStorage is LocalStorageService
            ? clientOrStorage
            : storage;

  static const String _storageKey = 'appointmentpro_customers';

  Future<List<CustomerModel>> _loadFromStorage() async {
    final storage = _storage;
    if (storage == null) return [];
    final raw = await storage.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) =>
                CustomerModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToStorage(List<CustomerModel> list) async {
    final storage = _storage;
    if (storage == null) return;
    final encoded = jsonEncode(list.map((c) => c.toJson()).toList());
    await storage.setString(_storageKey, encoded);
  }

  /// Fetch all customers for a business with optional search keyword
  Future<List<CustomerModel>> getCustomers(
    String businessId, {
    String? search,
  }) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final query = <String, dynamic>{
          if (businessId.isNotEmpty) 'businessId': businessId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        };

        final response = await client.get(
          ApiEndpoints.customers,
          queryParameters: query,
        );
        final rawData = response['data'];

        if (rawData is List) {
          return rawData
              .map(
                (item) =>
                    CustomerModel.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
        }
        return [];
      } catch (e) {
        if (_storage == null) rethrow;
      }
    }

    final all = await _loadFromStorage();
    return all.where((c) {
      if (businessId.isNotEmpty && c.businessId != businessId) return false;
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            (c.email != null && c.email!.toLowerCase().contains(q));
      }
      return true;
    }).toList();
  }

  /// Get single customer profile by ID
  Future<CustomerModel?> getCustomerById(String id) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final response = await client.get(ApiEndpoints.customerById(id));
        final rawData = response['data'];
        if (rawData is Map) {
          return CustomerModel.fromJson(Map<String, dynamic>.from(rawData));
        }
        return null;
      } catch (e) {
        if (_storage == null) rethrow;
      }
    }

    final all = await _loadFromStorage();
    return all.where((c) => c.id == id).firstOrNull;
  }

  /// Create or upsert customer in business client ledger
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final body = {
          'businessId': customer.businessId,
          'name': customer.name,
          'countryCode': customer.countryCode,
          'phone': customer.phone,
          if (customer.email != null && customer.email!.trim().isNotEmpty)
            'email': customer.email!.trim(),
          if (customer.notes != null && customer.notes!.trim().isNotEmpty)
            'notes': customer.notes!.trim(),
        };

        final response = await client.post(
          ApiEndpoints.customers,
          data: body,
        );
        final data = response['data'] as Map<String, dynamic>;
        return CustomerModel.fromJson(data);
      } catch (e) {
        if (_storage == null) rethrow;
      }
    }

    final all = await _loadFromStorage();
    final index = all.indexWhere(
      (c) => c.businessId == customer.businessId && c.phone == customer.phone,
    );
    if (index != -1) {
      all[index] = customer;
    } else {
      all.add(customer);
    }
    await _saveToStorage(all);
    return customer;
  }

  /// Update an existing customer
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final client = _apiClient;
    if (client != null) {
      try {
        final body = {
          'name': customer.name,
          'countryCode': customer.countryCode,
          'phone': customer.phone,
          if (customer.email != null) 'email': customer.email!.trim(),
          if (customer.notes != null) 'notes': customer.notes!.trim(),
        };

        final response = await client.put(
          ApiEndpoints.customerById(customer.id),
          data: body,
        );
        final data = response['data'] as Map<String, dynamic>;
        return CustomerModel.fromJson(data);
      } catch (e) {
        if (_storage == null) rethrow;
      }
    }

    final all = await _loadFromStorage();
    final index = all.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      all[index] = customer;
      await _saveToStorage(all);
    }
    return customer;
  }

  /// Delete a customer
  Future<void> deleteCustomer(String id) async {
    final client = _apiClient;
    if (client != null) {
      try {
        await client.delete(ApiEndpoints.customerById(id));
        return;
      } catch (e) {
        if (_storage == null) rethrow;
      }
    }

    final all = await _loadFromStorage();
    all.removeWhere((c) => c.id == id);
    await _saveToStorage(all);
  }
}
