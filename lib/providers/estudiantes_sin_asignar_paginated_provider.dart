import 'paginated_data_provider.dart';
import '../services/academic_service.dart' as academic_service;
import '../models/user.dart';

class EstudiantesSinAsignarPaginatedProvider extends PaginatedDataProvider<User> {
  final academic_service.AcademicService _academicService = academic_service.AcademicService();

  @override
  Future<PaginatedResponse<User>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final response = await _academicService.getEstudiantesSinAsignar(accessToken, page: page, limit: limit);
    if (response == null) return null;
    return PaginatedResponse(items: response.users, pagination: response.pagination);
  }

  @override
  Future<User?> createItemApi(String accessToken, data) async {
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
