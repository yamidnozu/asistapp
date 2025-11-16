import 'paginated_data_provider.dart';
import '../services/academic_service.dart' as academic_service;
import '../models/grupo.dart'; // contains PeriodoAcademico

class PeriodoPaginatedProvider extends PaginatedDataProvider<PeriodoAcademico> {
  final academic_service.AcademicService _academicService = academic_service.AcademicService();

  @override
  Future<PaginatedResponse<PeriodoAcademico>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final response = await _academicService.getPeriodosAcademicos(accessToken, page: page, limit: limit);
    if (response == null) return null;
    return PaginatedResponse(items: response.periodosAcademicos, pagination: response.pagination);
  }

  @override
  Future<PeriodoAcademico?> createItemApi(String accessToken, dynamic data) async {
    final created = await _academicService.createPeriodoAcademico(accessToken, data as academic_service.CreatePeriodoAcademicoRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _academicService.deletePeriodoAcademico(accessToken, id);
  }

  @override
  Future<PeriodoAcademico?> updateItemApi(String accessToken, String id, dynamic data) async {
    final updated = await _academicService.updatePeriodoAcademico(accessToken, id, data as academic_service.UpdatePeriodoAcademicoRequest);
    return updated;
  }
}
