import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

class DatabaseHelper{
  Future<Database> initDB() async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'caixafacil.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      // tabela agencias para armazenar dados de agências da Caixa
      const sqlAgencias = "CREATE TABLE IF NOT EXISTS agencias("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "nome TEXT,"
          "endereco TEXT,"
          "latitude REAL,"
          "longitude REAL,"
          "ocupacaoAtual INTEGER,"
          "capacidade INTEGER,"
          "horario TEXT,"
          "ultimaAtualizacao TEXT);";
      await db.execute(sqlAgencias);
    }, onUpgrade: (db, oldVersion, newVersion) async {
      // Caso seja necessário suportar upgrades futuros, aqui podemos aplicar
      // migrações. Por ora, asseguramos que a tabela 'agencias' exista.
      const sqlAgencias = "CREATE TABLE IF NOT EXISTS agencias("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "nome TEXT,"
          "endereco TEXT,"
          "latitude REAL,"
          "longitude REAL,"
          "ocupacaoAtual INTEGER,"
          "capacidade INTEGER,"
          "horario TEXT,"
          "ultimaAtualizacao TEXT);";
      await db.execute(sqlAgencias);
    });
  }
}