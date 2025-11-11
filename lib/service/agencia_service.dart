import 'package:caixafacil_app/dao/agencia_dao.dart';
import 'package:caixafacil_app/model/agencia.dart';
import 'package:caixafacil_app/service/agencia_api_service.dart';
import 'dart:math';

class AgenciaService {
  final _agenciaDao = AgenciaDao();

  Future<List<Agencia>?> findAll() async {
    return await _agenciaDao.findAll();
  }

  Future<List<Agencia>?> findNearby(Map<String, dynamic> perfil, {int limit = 50}) async {
    return await _agenciaDao.findNearby(perfil, limit: limit);
  }

  Future<int?> save(Agencia agencia) async {
    return await _agenciaDao.save(agencia);
  }

  Future<int?> alter(Agencia agencia) async {
    return await _agenciaDao.alter(agencia);
  }

  Future<int?> remove(Agencia agencia) async {
    return await _agenciaDao.remove(agencia);
  }

  /// Busca em uma "API" (simulada) agências próximas a lat/lon.
  Future<List<Agencia>> fetchFromApi(double lat, double lon, {double radiusKm = 10.0}) async {
    final list = await AgenciaApiService.fetchNearby(lat, lon, radiusKm: radiusKm);
    // opcional: persistir em DB (somente se desejar). Não persisto automaticamente para evitar duplicatas.
    return list;
  }

  /// Atualiza as ocupações das agências com valores aleatórios (0 .. capacidade * 1.2).
  Future<List<Agencia>> randomizeOccupancy(List<Agencia> agencias) async {
    final rnd = Random();
    for (var a in agencias) {
      final max = maxInt(1, a.capacidade);
      a.ocupacaoAtual = rnd.nextInt((max * 12) ~/ 10 + 1); // até 120% da capacidade
      // tenta persistir (se já existir no DB, alter retornará null/erro dependendo da implementação)
      try {
        await _agenciaDao.alter(a);
      } catch (_) {}
    }
    return agencias;
  }

  int maxInt(int a, int b) => a > b ? a : b;
}
