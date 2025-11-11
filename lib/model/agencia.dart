// Modelo para representar uma agência da Caixa Econômica Federal
// Inclui dados de localização e ocupação, utilitários para cálculo de
// distância (Haversine) e um método simples de score de compatibilidade
// com o perfil do usuário (para escolha de agências mais próximas e menos cheias).

import 'dart:math';

class Agencia {
  int? id;
  String nome;
  String endereco;
  double latitude;
  double longitude;
  // número estimado de pessoas na agência no momento
  int ocupacaoAtual;
  // capacidade estimada (pessoas que a agência comporta sem sobrecarga)
  int capacidade;
  // horário de funcionamento (texto livre ou JSON serializado)
  String horario;
  // data/hora da última atualização dos dados de ocupação
  DateTime? ultimaAtualizacao;
  // tipo de serviço: 'Agência Bancária', 'Lotérica', 'Caixa Eletrônico'
  String tipoServico;

  Agencia({
    this.id,
    required this.nome,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    this.ocupacaoAtual = 0,
    this.capacidade = 1,
    this.horario = '',
    this.ultimaAtualizacao,
    this.tipoServico = 'Agência Bancária',
  });

  // Converte para Map (útil para DAO/SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'ocupacaoAtual': ocupacaoAtual,
      'capacidade': capacidade,
      'horario': horario,
      'ultimaAtualizacao': ultimaAtualizacao?.toIso8601String(),
      'tipoServico': tipoServico,
    };
  }

  // Cria a instância a partir de um Map (DAO)
  factory Agencia.fromMap(Map<String, dynamic> map) {
    return Agencia(
      id: map['id'] as int?,
      nome: map['nome'] ?? '',
      endereco: map['endereco'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ocupacaoAtual: map['ocupacaoAtual'] ?? 0,
      capacidade: map['capacidade'] ?? 1,
      horario: map['horario'] ?? '',
      ultimaAtualizacao: map['ultimaAtualizacao'] != null
          ? DateTime.tryParse(map['ultimaAtualizacao'])
          : null,
      tipoServico: map['tipoServico'] ?? 'Agência Bancária',
    );
  }

  @override
  String toString() {
    return 'Agencia(id: $id, nome: $nome, endereco: $endereco, lat: $latitude, lon: $longitude, ocupacao: $ocupacaoAtual/$capacidade)';
  }

  // Taxa de ocupação (0.0 .. 1.0), protege divisão por zero
  double ocupacaoRate() {
    if (capacidade <= 0) return 1.0;
    return ocupacaoAtual / capacidade;
  }

  // Calcula distância em quilômetros entre esta agência e um ponto (lat, lon)
  // Usando fórmula de Haversine
  double distanciaPara(double lat, double lon) {
    const double R = 6371.0; // raio da Terra em km
    double dLat = _deg2rad(lat - latitude);
    double dLon = _deg2rad(lon - longitude);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(latitude)) *
            cos(_deg2rad(lat)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // Score simples de compatibilidade com o perfil do usuário.
  // O perfil esperado é um Map com chaves opcionais:
  // - 'latitude' (double), 'longitude' (double)
  // - 'max_distance_km' (double) preferido
  // - 'prefer_low_occupancy' (bool)
  // - 'max_occupancy_rate' (double) desejado (0..1)
  // Retorna um valor entre 0.0 (ruim) e 1.0 (ótimo).
  double scoreCompatibilidade(Map<String, dynamic> perfil) {
    // pontuação baseada em distância (0..1)
    double distanciaScore = 0.5;
    if (perfil.containsKey('latitude') && perfil.containsKey('longitude')) {
      double userLat = (perfil['latitude'] as num).toDouble();
      double userLon = (perfil['longitude'] as num).toDouble();
      double dist = distanciaPara(userLat, userLon); // km
      double maxDist = (perfil['max_distance_km'] as num?)?.toDouble() ?? 10.0;
      // distância 0 => 1.0, distância >= maxDist => 0.0, linear entre
      distanciaScore = (1.0 - (dist / maxDist)).clamp(0.0, 1.0);
    }

    // pontuação baseada em ocupação (0..1)
    double ocupacaoScore = 0.5;
    double rate = ocupacaoRate();
    bool preferLow = (perfil['prefer_low_occupancy'] as bool?) ?? true;
    double desiredMax =
        (perfil['max_occupancy_rate'] as num?)?.toDouble() ?? 0.5;
    if (preferLow) {
      // quanto menor a taxa em relação ao desejado, melhor
      if (rate <= desiredMax) {
        ocupacaoScore = 1.0;
      } else {
        // quando acima do desejado, reduzir linearmente até 0.0 quando rate=1.0
        ocupacaoScore = (1.0 - ((rate - desiredMax) / (1.0 - desiredMax)))
            .clamp(0.0, 1.0);
      }
    } else {
      // se usuário não prefere baixa ocupação, ocupação neutra
      ocupacaoScore = 0.5;
    }

    // Combina as duas pontuações (peso 0.6 distância, 0.4 ocupação) — ajustável
    double finalScore = (0.6 * distanciaScore) + (0.4 * ocupacaoScore);
    return finalScore.clamp(0.0, 1.0);
  }
}

double _deg2rad(double deg) => deg * (pi / 180.0);
