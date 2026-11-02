import 'package:flutter_test/flutter_test.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';

void main() {
  test('converte para mapa e de volta, com o instante em UTC ISO 8601', () {
    final original = Localizacao(
      latitude: -23.305123,
      longitude: -45.965432,
      precisao: 4.5,
      instante: DateTime.utc(2026, 11, 2, 18, 30, 5),
    );

    final mapa = original.paraMapa();
    expect(mapa.containsKey('id'), isFalse);
    expect(mapa['instante'], '2026-11-02T18:30:05.000Z');

    final lida = Localizacao.deMapa({...mapa, 'id': 7});
    expect(lida.id, 7);
    expect(lida.latitude, original.latitude);
    expect(lida.longitude, original.longitude);
    expect(lida.precisao, original.precisao);
    expect(lida.instante, original.instante);
    expect(lida.instante.isUtc, isTrue);
  });
}
