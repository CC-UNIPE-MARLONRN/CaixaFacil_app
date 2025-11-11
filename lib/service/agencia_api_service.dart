import 'dart:math';
import 'package:caixafacil_app/model/agencia.dart';

class AgenciaApiService {
  /// Simula uma API retornando agências próximas a uma coordenada.
  /// Gera alguns pontos com nomes plausíveis e posições próximas ao ponto fornecido.
  static Future<List<Agencia>> fetchNearby(
    double lat,
    double lon, {
    double radiusKm = 10.0,
  }) async {
    // Gerar 8 agências com offsets aleatórios dentro de radiusKm
    final rnd = Random(lat.toInt() ^ lon.toInt());
    final List<String> nomes = [
      'Caixa Centro',
      'Caixa Bairro',
      'Caixa Terminal',
      'Caixa Loteria São Paulo',
      'Caixa Rio Rua Sul',
      'Caixa Av. Central',
      'Caixa Shopping',
      'Caixa Estação',
    ];

    List<Agencia> result = [];
    for (int i = 0; i < nomes.length; i++) {
      // gera distância aleatória até radiusKm e ângulo
      final d = rnd.nextDouble() * radiusKm; // km
      final angle = rnd.nextDouble() * 2 * pi;
      // aproximar conversão simples: 1 deg lat ~111 km, 1 deg lon ~111*cos(lat)
      final dLat = (d / 111.0) * sin(angle);
      final dLon = (d / (111.0 * cos(lat * pi / 180.0))) * cos(angle);
      final tipos = ['Agência Bancária', 'Lotérica', 'Caixa Eletrônico'];
      final a = Agencia(
        nome: nomes[i],
        endereco: '${(100 + i)} Avenida Principal',
        latitude: lat + dLat,
        longitude: lon + dLon,
        ocupacaoAtual: rnd.nextInt(20),
        capacidade: 20 + rnd.nextInt(40),
        horario: '08:00-16:00',
        ultimaAtualizacao: DateTime.now(),
        tipoServico: tipos[rnd.nextInt(tipos.length)],
      );
      result.add(a);
    }
    // pequena simulação de latência
    await Future.delayed(Duration(milliseconds: 400));
    return result;
  }
}
