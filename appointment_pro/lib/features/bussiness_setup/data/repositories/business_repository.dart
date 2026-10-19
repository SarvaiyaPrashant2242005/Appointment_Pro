import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/api_client.dart';
import '../models/business_model.dart';

class BusinessRepository {
  final ApiClient _apiClient;

  BusinessRepository(this._apiClient);

  /// Fetches all businesses owned by the authenticated user from the API.
  Future<List<BusinessModel>> getBusinesses() async {
    final response = await _apiClient.get(ApiEndpoints.businesses);
    final rawData = response['data'];

    if (rawData is List) {
      return rawData
          .map(
            (item) =>
                BusinessModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }

    return [];
  }

  /// Fetches a specific business by its UUID.
  Future<BusinessModel> getBusinessById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.businessById(id));
    final data = response['data'] as Map<String, dynamic>;
    return BusinessModel.fromJson(data);
  }

  /// Public business lookup by slug for customer bookings.
  Future<BusinessModel> getPublicBusinessBySlug(String slug) async {
    final response = await _apiClient.get(ApiEndpoints.businessPublic(slug));
    final data = response['data'] as Map<String, dynamic>;
    return BusinessModel.fromJson(data);
  }

  /// Creates a new business for the authenticated user.
  /// Supports optional multipart image upload for the business logo.
  Future<List<BusinessModel>> createBusiness(BusinessModel business) async {
    final apiMap = business.toApiMap();

    final logoPath = business.logoPath;
    final hasLocalLogo =
        logoPath != null &&
        !logoPath.startsWith('http://') &&
        !logoPath.startsWith('https://') &&
        !logoPath.startsWith('/') &&
        File(logoPath).existsSync();

    if (hasLocalLogo) {
      final fileName = logoPath.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        ...apiMap,
        'logo': await MultipartFile.fromFile(logoPath, filename: fileName),
      });

      await _apiClient.post(ApiEndpoints.businesses, data: formData);
    } else {
      await _apiClient.post(ApiEndpoints.businesses, data: apiMap);
    }

    return getBusinesses();
  }

  /// Updates existing business details and handles logo replacement.
  Future<List<BusinessModel>> updateBusiness(BusinessModel business) async {
    final apiMap = business.toApiMap();

    final logoPath = business.logoPath;
    final isNewLocalLogo =
        logoPath != null &&
        !logoPath.startsWith('http://') &&
        !logoPath.startsWith('https://') &&
        !logoPath.startsWith('/') &&
        File(logoPath).existsSync();

    final endpoint = ApiEndpoints.businessById(business.id);

    if (isNewLocalLogo) {
      final fileName = logoPath.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        ...apiMap,
        'logo': await MultipartFile.fromFile(logoPath, filename: fileName),
      });

      await _apiClient.put(endpoint, data: formData);
    } else {
      await _apiClient.put(endpoint, data: apiMap);
    }

    return getBusinesses();
  }

  /// Activates the selected business and deactivates other businesses for this user.
  Future<List<BusinessModel>> setActiveBusiness(String id) async {
    await _apiClient.patch(ApiEndpoints.businessActivate(id));
    return getBusinesses();
  }

  /// Deletes a business and returns the refreshed list of businesses.
  Future<List<BusinessModel>> deleteBusiness(String id) async {
    await _apiClient.delete(ApiEndpoints.businessById(id));
    return getBusinesses();
  }
}
