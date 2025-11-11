import 'package:caixafacil_app/model/agencia.dart';
import 'package:caixafacil_app/service/agencia_service.dart';
import 'package:caixafacil_app/service/geocoding_service.dart';

class AgenciaController {
  final _service = AgenciaService();

  Future<List<Agencia>?> findAll() async {
    return await _service.findAll();
  }

  Future<List<Agencia>?> findNearby(Map<String, dynamic> perfil, {int limit = 50}) async {
    return await _service.findNearby(perfil, limit: limit);
  }

  Future<Agencia?> recommend(Map<String, dynamic> perfil) async {
    final list = await _service.findNearby(perfil, limit: 10);
    if (list == null || list.isEmpty) return null;
    // A lista já vem ordenada pelo score (DAO). Retornamos a melhor.
    return list.first;
  }

  /// Busca por endereço (texto) ou coordenadas; se endereço, geocodifica e
  /// busca agências via API (simulada). Retorna lista de agências.
  Future<List<Agencia>?> searchByAddressOrCoords(String query, {double maxDistanceKm = 10.0}) async {
    double? lat;
    double? lon;
    // se parecer com lat,lon (ex: -23.5,-46.6)
    final parts = query.split(',');
    if (parts.length == 2) {
      lat = double.tryParse(parts[0].trim());
      lon = double.tryParse(parts[1].trim());
    }
    if (lat == null || lon == null) {
      // tenta geocodificar
      final geo = await GeocodingService.geocode(query);
      if (geo == null) return null;
      lat = geo['lat'];
      lon = geo['lon'];
    }

    final list = await _service.fetchFromApi(lat!, lon!, radiusKm: maxDistanceKm);
    return list;
  }

  Future<List<Agencia>> randomizeOccupancy(List<Agencia> agencias) async {
    return await _service.randomizeOccupancy(agencias);
  }

  Future<int?> save(Agencia agencia) async {
    return await _service.save(agencia);
  }

  Future<int?> alter(Agencia agencia) async {
    return await _service.alter(agencia);
  }

  Future<int?> remove(Agencia agencia) async {
    return await _service.remove(agencia);
  }
}
