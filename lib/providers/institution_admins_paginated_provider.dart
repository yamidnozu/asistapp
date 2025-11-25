import 'package:flutter/foundation.dart';
import 'paginated_data_mixin.dart';
import '../models/pagination_types.dart';
import '../services/user_service.dart' as user_service;
import '../models/user.dart';

class InstitutionAdminsPaginatedProvider extends ChangeNotifier with PaginatedDataMixin<User> {
  final user_service.UserService _userService;

  InstitutionAdminsPaginatedProvider({user_service.UserService? userService})
      : _userService = userService ?? user_service.UserService();

  /// Expected filters: 'institutionId'
  @override
  Future<PaginatedResponse<User>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final institutionId = filters?['institutionId'];
    if (institutionId == null || institutionId.isEmpty) return null;
    // Forward 'search' to backend so the provider can do remote search.
    final response = await _userService.getUsersByInstitution(
      accessToken,
      institutionId,
      page: page,
      limit: limit ?? 5,
      role: 'admin_institucion',
      search: search,
    );
    if (response == null) return null;
    return PaginatedResponse(items: response.users, pagination: response.pagination);
  }

  @override
  Future<User?> createItemApi(String accessToken, dynamic data) async {
    return null;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return false;
  }

  @override
  Future<User?> updateItemApi(String accessToken, String id, dynamic data) async {
    return null;
  }
}
