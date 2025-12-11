import 'package:flutter/foundation.dart';
import '../models/pagination_types.dart';
import 'paginated_data_mixin.dart';
import '../services/academic/horario_service.dart';
import '../models/horario.dart';

class HorarioPaginatedProvider extends ChangeNotifier
    with PaginatedDataMixin<Horario> {
  final HorarioService _horarioService;

  HorarioPaginatedProvider({HorarioService? horarioService})
      : _horarioService = horarioService ?? HorarioService();

  /// Support filters: 'grupoId' and 'periodoId'
  @override
  Future<PaginatedResponse<Horario>?> fetchPage(String accessToken,
      {int page = 1,
      int? limit,
      String? search,
      Map<String, String>? filters}) async {
    final grupoId = filters?['grupoId'];
    final periodoId = filters?['periodoId'];

    final response = await _horarioService.getHorarios(accessToken,
        page: page, limit: limit, grupoId: grupoId, periodoId: periodoId);
    if (response == null) return null;
    return PaginatedResponse(
        items: response.horarios, pagination: response.pagination);
  }

  @override
  Future<Horario?> createItemApi(String accessToken, dynamic data) async {
    final created = await _horarioService.createHorario(
        accessToken, data as CreateHorarioRequest);
    return created;
  }

  @override
  Future<bool> deleteItemApi(String accessToken, String id) async {
    return await _horarioService.deleteHorario(accessToken, id);
  }

  @override
  Future<Horario?> updateItemApi(
      String accessToken, String id, dynamic data) async {
    final updated = await _horarioService.updateHorario(
        accessToken, id, data as UpdateHorarioRequest);
    return updated;
  }
}
