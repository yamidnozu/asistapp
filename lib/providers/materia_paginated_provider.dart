import 'paginated_data_provider.dart';
import '../services/academic_service.dart' as academic_service;
import '../models/materia.dart';

class MateriaPaginatedProvider extends PaginatedDataProvider<Materia> {
  final academic_service.AcademicService _academicService = academic_service.AcademicService();

  @override
  Future<PaginatedResponse<Materia>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final response = await _academicService.getMaterias(accessToken, page: page, limit: limit, search: search);
    if (response == null) return null;
    return PaginatedResponse(items: response.materias, pagination: response.pagination);
  }

  @override
  Future<Materia?> createItemApi(String accessToken, dynamic data) async {
    final created = await _academicService.createMateria(accessToken, data as academic_service.CreateMateriaRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _academicService.deleteMateria(accessToken, id);
  }

  @override
  Future<Materia?> updateItemApi(String accessToken, String id, dynamic data) async {
    final updated = await _academicService.updateMateria(accessToken, id, data as academic_service.UpdateMateriaRequest);
    return updated;
  }
}
