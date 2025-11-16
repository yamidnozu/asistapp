import 'paginated_data_provider.dart';
import '../services/user_service.dart' as user_service;
import '../models/user.dart';

class UserPaginatedProvider extends PaginatedDataProvider<User> {
  final user_service.UserService _userService = user_service.UserService();

  /// Support filters: 'institutionId' in filters map for loading users by institution.
  @override
  Future<PaginatedResponse<User>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final institutionId = filters?['institutionId'];
    final role = filters?['role'];

    if (institutionId != null && institutionId.isNotEmpty) {
      final response = await _userService.getUsersByInstitution(
        accessToken,
        institutionId,
        page: page,
        limit: limit ?? 5,
        role: role,
      );
      if (response == null) return null;
      return PaginatedResponse(items: response.users, pagination: response.pagination);
    }

  // Support optional role filter for searching by role.
  final roles = role != null ? [role] : null;
  final response = await _userService.getAllUsers(accessToken, page: page, limit: limit, search: search, roles: roles);
    if (response == null) return null;
    return PaginatedResponse(items: response.users, pagination: response.pagination);
  }

  @override
  Future<User?> createItemApi(String accessToken, data) async {
  final created = await _userService.createUser(accessToken, data as CreateUserRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _userService.deleteUser(accessToken, id);
  }

  @override
  Future<User?> updateItemApi(String accessToken, String id, dynamic data) async {
  final updated = await _userService.updateUser(accessToken, id, data as UpdateUserRequest);
    return updated;
  }
}
