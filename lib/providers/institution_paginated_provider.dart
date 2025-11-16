import 'paginated_data_provider.dart';
import '../services/institution_service.dart';
import '../models/institution.dart';

class InstitutionPaginatedProvider extends PaginatedDataProvider<Institution> {
  final InstitutionService _service = InstitutionService();

  @override
  Future<PaginatedResponse<Institution>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    final active = filters?['activa'];
    final response = await _service.getAllInstitutions(accessToken, page: page, limit: limit, activa: active == 'true');
    if (response == null) return null;
    return PaginatedResponse(items: response.institutions, pagination: response.pagination);
  }

  @override
  Future<Institution?> createItemApi(String accessToken, dynamic data) async {
    final map = data as Map<String, dynamic>;
    final created = await _service.createInstitution(
      accessToken,
      nombre: map['nombre'] as String,
      direccion: map['direccion'] as String?,
      telefono: map['telefono'] as String?,
      email: map['email'] as String?,
    );
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _service.deleteInstitution(accessToken, id);
  }

  @override
  Future<Institution?> updateItemApi(String accessToken, String id, dynamic data) async {
    final updated = await _service.updateInstitution(accessToken, id,
      nombre: data['nombre'] as String?,
      direccion: data['direccion'] as String?,
      telefono: data['telefono'] as String?,
      email: data['email'] as String?,
      activa: data['activa'] as bool?,
    );
    return updated;
  }
}
