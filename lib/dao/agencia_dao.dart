import '../database/database_helper.dart';
import '../model/agencia.dart';

class AgenciaDao {
  late DatabaseHelper dbHelper;

  AgenciaDao() {
    dbHelper = DatabaseHelper();
  }

  Future<int?> save(Agencia agencia) async {
    final db = await dbHelper.initDB();
    try {
      return await db.insert('agencias', agencia.toMap());
    } catch (e) {
      print(e);
      return null;
    } finally {
      db.close();
    }
  }

  Future<int?> alter(Agencia agencia) async {
    final db = await dbHelper.initDB();
    try {
      return await db.update(
        'agencias',
        agencia.toMap(),
        where: 'id = ?',
        whereArgs: [agencia.id],
      );
    } catch (e) {
      print(e);
      return null;
    } finally {
      db.close();
    }
  }

  Future<int?> remove(Agencia agencia) async {
    final db = await dbHelper.initDB();
    try {
      return await db.delete(
        'agencias',
        where: 'id = ?',
        whereArgs: [agencia.id],
      );
    } catch (e) {
      print(e);
      return null;
    } finally {
      db.close();
    }
  }

  Future<List<Agencia>?> findAll() async {
    final db = await dbHelper.initDB();
    try {
      final listMap = await db.query('agencias');
      List<Agencia> agencias = [];
      for (var map in listMap) {
        agencias.add(Agencia.fromMap(map));
      }
      return agencias;
    } catch (e) {
      print(e);
      return null;
    } finally {
      db.close();
    }
  }

  /// Retorna agências compatíveis com o perfil do usuário, ordenadas pelo
  /// score de compatibilidade (maior primeiro). Se o perfil contém
  /// 'latitude' e 'longitude' e 'max_distance_km', filtra por distância.
  Future<List<Agencia>?> findNearby(
    Map<String, dynamic> perfil, {
    int limit = 50,
  }) async {
    final db = await dbHelper.initDB();
    try {
      final listMap = await db.query('agencias');
      List<Agencia> agencias = listMap.map((m) => Agencia.fromMap(m)).toList();

      double? maxDist;
      if (perfil.containsKey('max_distance_km')) {
        maxDist = (perfil['max_distance_km'] as num).toDouble();
      }

      // Calcula score para cada agência e aplica filtro por distância quando aplicável
      final scored = <Map<String, dynamic>>[];
      for (var a in agencias) {
        if (perfil.containsKey('latitude') &&
            perfil.containsKey('longitude') &&
            maxDist != null) {
          final userLat = (perfil['latitude'] as num).toDouble();
          final userLon = (perfil['longitude'] as num).toDouble();
          final dist = a.distanciaPara(userLat, userLon);
          if (dist > maxDist) continue; // pular agências fora do alcance
        }
        final s = a.scoreCompatibilidade(perfil);
        scored.add({'agencia': a, 'score': s});
      }

      // Ordena pelo score desc
      scored.sort(
        (x, y) => (y['score'] as double).compareTo(x['score'] as double),
      );

      // Retorna somente as agências ordenadas (até o limite)
      final result = scored
          .take(limit)
          .map((e) => e['agencia'] as Agencia)
          .toList();
      return result;
    } catch (e) {
      print(e);
      return null;
    } finally {
      db.close();
    }
  }
}
