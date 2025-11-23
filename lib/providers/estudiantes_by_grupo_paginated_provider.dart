import 'package:flutter/foundation.dart';
import 'paginated_data_mixin.dart';
import '../models/pagination_types.dart';
import '../services/academic/grupo_service.dart';
import '../models/user.dart';

class EstudiantesByGrupoPaginatedProvider extends ChangeNotifier with PaginatedDataMixin<User> {
  final GrupoService _grupoService;

  EstudiantesByGrupoPaginatedProvider({GrupoService? grupoService})
      : _grupoService = grupoService ?? GrupoService();

  @override
  Future<PaginatedResponse<User>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
      final grupoId = filters?['grupoId']?.trim();

      if (grupoId == null || grupoId.isEmpty) {
        return null;
      }

      final response = await _grupoService.getEstudiantesByGrupo(
        accessToken,
        grupoId,
        page: page,
        limit: limit,
      );

      if (response == null) {
        return null;
      }

      return PaginatedResponse(
        items: response.users,
        pagination: response.pagination,
      );
  }

  @override
  Future<User?> createItemApi(String accessToken, data) async {
    // Not supported here
    return null;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    // Not supported here
    return false;
  }

  @override
  Future<User?> updateItemApi(String accessToken, String id, dynamic data) async {
    // Not supported here
    return null;
  }
}
