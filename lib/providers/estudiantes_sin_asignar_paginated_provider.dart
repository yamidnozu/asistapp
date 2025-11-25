import 'package:flutter/foundation.dart';
import '../models/pagination_types.dart';
import 'paginated_data_mixin.dart';
import '../services/academic/grupo_service.dart';
import '../models/user.dart';

class EstudiantesSinAsignarPaginatedProvider extends ChangeNotifier with PaginatedDataMixin<User> {
  final GrupoService _grupoService;

  EstudiantesSinAsignarPaginatedProvider({GrupoService? grupoService})
      : _grupoService = grupoService ?? GrupoService();

  @override
  Future<PaginatedResponse<User>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
  final response = await _grupoService.getEstudiantesSinAsignar(accessToken, page: page, limit: limit);
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
