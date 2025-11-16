import 'paginated_data_provider.dart';
import '../services/academic_service.dart' as academic_service;
import '../models/horario.dart';

class HorarioPaginatedProvider extends PaginatedDataProvider<Horario> {
  final academic_service.AcademicService _academicService = academic_service.AcademicService();

  /// Support filters: 'grupoId' and 'periodoId'
  @override
  Future<PaginatedResponse<Horario>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final grupoId = filters?['grupoId'];
    final periodoId = filters?['periodoId'];

  final response = await _academicService.getHorarios(accessToken, page: page, limit: limit, grupoId: grupoId, periodoId: periodoId);
    if (response == null) return null;
    return PaginatedResponse(items: response.horarios, pagination: response.pagination);
  }

  @override
  Future<Horario?> createItemApi(String accessToken, dynamic data) async {
    final created = await _academicService.createHorario(accessToken, data as academic_service.CreateHorarioRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _academicService.deleteHorario(accessToken, id);
  }

  @override
  Future<Horario?> updateItemApi(String accessToken, String id, dynamic data) async {
    final updated = await _academicService.updateHorario(accessToken, id, data as academic_service.UpdateHorarioRequest);
    return updated;
  }
}
