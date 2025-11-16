// No direct foundation usage here; PaginatedDataProvider already mixes ChangeNotifier.
import 'paginated_data_provider.dart';
import '../services/academic_service.dart' as academic_service;
import '../models/grupo.dart';

/// Canary provider that uses the generic PaginatedDataProvider for Grupo.
///
/// This lives alongside the original GrupoProvider during migration. It
/// implements the minimal methods required by the base class and keeps
/// compatibility with the existing AcademicService signatures.
class GrupoPaginatedProvider extends PaginatedDataProvider<Grupo> {
  final academic_service.AcademicService _academicService = academic_service.AcademicService();

  /// Optional filter used by the UI to load groups by periodo.
  String? selectedPeriodoId;

  @override
  Future<PaginatedResponse<Grupo>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    // Support passing periodoId either via filters map or via the provider state
    final periodoId = filters?['periodoId'] ?? selectedPeriodoId;

    final response = await _academicService.getGrupos(accessToken, page: page, limit: limit, periodoId: periodoId, search: search);
    if (response == null) return null;

    return PaginatedResponse(items: response.grupos, pagination: response.pagination);
  }

  @override
  Future<Grupo?> createItemApi(String accessToken, dynamic data) async {
    // data is expected to be an academic_service.CreateGrupoRequest
    final created = await _academicService.createGrupo(accessToken, data as academic_service.CreateGrupoRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _academicService.deleteGrupo(accessToken, id);
  }

  @override
  Future<Grupo?> updateItemApi(String accessToken, String id, dynamic data) async {
    final updated = await _academicService.updateGrupo(accessToken, id, data as academic_service.UpdateGrupoRequest);
    return updated;
  }

  // Use the default _getItemId from the base class which extracts id from objects
}
