import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../tema.dart';
import '../../models/localizacao.dart';
import 'item_localizacao.dart';

/// Mapa com a camada de ruas do OpenStreetMap, o trajeto e um marcador por
/// localização. A mais recente fica em vermelho. Tocar num marcador mostra a
/// ficha daquela posição.
class MapaLocalizacoes extends StatefulWidget {
  const MapaLocalizacoes({super.key, required this.localizacoes, this.cache});

  /// Da mais recente para a mais antiga (como vem do repositório).
  final List<Localizacao> localizacoes;

  /// Cache das imagens preparado por `CacheMapa`; nulo = sem cache.
  final MapCachingProvider? cache;

  @override
  State<MapaLocalizacoes> createState() => _MapaLocalizacoesState();
}

class _MapaLocalizacoesState extends State<MapaLocalizacoes> {
  final _controlador = MapController();
  late final _imagens = NetworkTileProvider(cachingProvider: widget.cache);

  List<LatLng> get _pontos => [
    for (final l in widget.localizacoes) LatLng(l.latitude, l.longitude),
  ];

  /// Enquadra todos os pontos, sem aproximar demais quando há um só.
  CameraFit get _enquadramento => CameraFit.coordinates(
    coordinates: _pontos,
    padding: const EdgeInsets.fromLTRB(48, 96, 48, 96),
    maxZoom: 17,
  );

  void _enquadrar() => _controlador.fitCamera(_enquadramento);

  @override
  void didUpdateWidget(MapaLocalizacoes anterior) {
    super.didUpdateWidget(anterior);
    // Registros atualizados: enquadra de novo depois que o mapa redesenhar.
    if (anterior.localizacoes != widget.localizacoes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enquadrar();
      });
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _mostrarDetalhes(Localizacao localizacao, bool maisRecente) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ItemLocalizacao(
            localizacao: localizacao,
            maisRecente: maisRecente,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maisRecente = widget.localizacoes.first;
    final anteriores = widget.localizacoes.skip(1);

    return Stack(
      children: [
        FlutterMap(
          mapController: _controlador,
          options: MapOptions(
            initialCameraFit: _enquadramento,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // A política do OpenStreetMap exige identificar o app.
              userAgentPackageName: 'com.rvmcosta.localizacoes',
              tileProvider: _imagens,
              maxNativeZoom: 19,
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _pontos,
                  color: Cores.tinta.withValues(alpha: 0.45),
                  strokeWidth: 2,
                  pattern: StrokePattern.dashed(segments: const [6, 5]),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                // As antigas primeiro, para a mais recente ficar por cima.
                for (final l in anteriores.toList().reversed)
                  Marker(
                    point: LatLng(l.latitude, l.longitude),
                    width: 22,
                    height: 22,
                    child: GestureDetector(
                      onTap: () => _mostrarDetalhes(l, false),
                      child: const _Ponto(),
                    ),
                  ),
                Marker(
                  point: LatLng(maisRecente.latitude, maisRecente.longitude),
                  width: 44,
                  height: 44,
                  // A ponta do alfinete fica sobre a coordenada.
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _mostrarDetalhes(maisRecente, true),
                    child: const Icon(
                      Icons.location_on,
                      color: Cores.vermelho,
                      size: 44,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
                    ),
                  ),
                ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
              alignment: Alignment.bottomLeft,
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          child: _Legenda(total: widget.localizacoes.length),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _enquadrar,
            backgroundColor: Cores.tinta,
            foregroundColor: Cores.folha,
            icon: const Icon(Icons.fit_screen_outlined),
            label: Text('Enquadrar', style: estiloDados(cor: Cores.folha)),
          ),
        ),
      ],
    );
  }
}

/// Marcador das posições anteriores: bolinha verde com borda branca.
class _Ponto extends StatelessWidget {
  const _Ponto();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: Cores.musgo,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Cores.folha.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Cores.linha),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _itemLegenda(Cores.vermelho, 'mais recente'),
          const SizedBox(height: 4),
          _itemLegenda(Cores.musgo, 'anteriores (${total - 1})'),
        ],
      ),
    );
  }

  Widget _itemLegenda(Color cor, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(texto, style: estiloDados(tamanho: 11)),
      ],
    );
  }
}
