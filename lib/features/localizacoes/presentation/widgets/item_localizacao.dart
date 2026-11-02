import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../tema.dart';
import '../../models/localizacao.dart';

/// Ficha de uma localização: data e hora locais, latitude, longitude e
/// precisão. Usada no histórico, na tela inicial e nos detalhes do mapa.
class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({
    super.key,
    required this.localizacao,
    this.maisRecente = false,
  });

  final Localizacao localizacao;

  /// Marca a ficha em vermelho, como o marcador mais recente no mapa.
  final bool maisRecente;

  static final _formatoHora = DateFormat('HH:mm:ss');
  static final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    // O banco guarda em UTC; aqui convertemos para o horário do aparelho.
    final local = localizacao.instante.toLocal();
    final corMarca = maisRecente ? Cores.vermelho : Cores.musgo;
    final id = localizacao.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: corMarca,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(_formatoHora.format(local), style: estiloTitulo(19)),
                      const SizedBox(width: 8),
                      Text(
                        _formatoData.format(local),
                        style: estiloDados(tamanho: 12, cor: Cores.tintaSuave),
                      ),
                      const Spacer(),
                      if (maisRecente)
                        Text(
                          'MAIS RECENTE',
                          style: estiloDados(
                            tamanho: 10,
                            cor: Cores.vermelho,
                            peso: FontWeight.w500,
                            espacamento: 1,
                          ),
                        )
                      else if (id != null)
                        Text(
                          'Nº $id',
                          style: estiloDados(
                            tamanho: 11,
                            cor: Cores.tintaSuave,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Coordenada(
                              rotulo: 'lat',
                              valor: localizacao.latitude,
                            ),
                            const SizedBox(height: 2),
                            _Coordenada(
                              rotulo: 'lon',
                              valor: localizacao.longitude,
                            ),
                          ],
                        ),
                      ),
                      _Precisao(metros: localizacao.precisao),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Coordenada extends StatelessWidget {
  const _Coordenada({required this.rotulo, required this.valor});

  final String rotulo;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            rotulo,
            style: estiloDados(tamanho: 11, cor: Cores.tintaSuave),
          ),
        ),
        // Seis casas decimais ≈ 11 cm de resolução.
        Text(valor.toStringAsFixed(6), style: estiloDados(tamanho: 14)),
      ],
    );
  }
}

class _Precisao extends StatelessWidget {
  const _Precisao({required this.metros});

  final double metros;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Cores.papel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Cores.linha),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'PRECISÃO',
            style: estiloDados(
              tamanho: 9,
              cor: Cores.tintaSuave,
              espacamento: 1,
            ),
          ),
          Text(
            '± ${metros.toStringAsFixed(1)} m',
            style: estiloDados(tamanho: 13, peso: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
