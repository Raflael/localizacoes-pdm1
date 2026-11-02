/// Um registro de posição salvo no banco.
class Localizacao {
  const Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  });

  /// Gerado pelo SQLite (autoincremento); é nulo antes de inserir.
  final int? id;
  final double latitude;
  final double longitude;

  /// Precisão estimada, em metros.
  final double precisao;

  /// Momento da leitura, sempre em UTC.
  final DateTime instante;

  /// Converte para o mapa gravado na tabela `localizacoes`.
  /// O instante vai como texto ISO 8601 em UTC (ex.: 2026-11-02T18:30:05.000Z).
  Map<String, Object?> paraMapa() {
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'precisao': precisao,
      'instante': instante.toUtc().toIso8601String(),
    };
  }

  /// Monta o objeto a partir de uma linha lida do banco.
  factory Localizacao.deMapa(Map<String, Object?> mapa) {
    return Localizacao(
      id: mapa['id'] as int,
      latitude: (mapa['latitude'] as num).toDouble(),
      longitude: (mapa['longitude'] as num).toDouble(),
      precisao: (mapa['precisao'] as num).toDouble(),
      instante: DateTime.parse(mapa['instante'] as String).toUtc(),
    );
  }
}
