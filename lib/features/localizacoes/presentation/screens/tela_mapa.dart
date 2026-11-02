import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/aviso_tela.dart';
import '../widgets/mapa_localizacoes.dart';

/// Carrega as 100 posições mais recentes e prepara o cache antes de
/// mostrar o mapa. Trata os estados de espera, erro e histórico vazio.
class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final _repositorio = RepositorioLocalizacoes();

  List<Localizacao>? _localizacoes;
  MapCachingProvider? _cache;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final cache = _cache ?? await CacheMapa.preparar();
      final registros = await _repositorio.buscarRecentes();
      if (!mounted) return;
      setState(() {
        _cache = cache;
        _localizacoes = registros;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível ler as localizações salvas.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
        // Barra fina de progresso ao atualizar com o mapa já na tela.
        bottom: _carregando && _localizacoes != null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    final localizacoes = _localizacoes;
    final erro = _erro;

    if (erro != null) {
      return Center(
        child: AvisoTela(
          icone: Icons.error_outline,
          titulo: 'Algo deu errado',
          mensagem: erro,
          textoBotao: 'Tentar novamente',
          aoPressionar: _carregar,
        ),
      );
    }
    if (localizacoes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (localizacoes.isEmpty) {
      return Center(
        child: AvisoTela(
          icone: Icons.map_outlined,
          titulo: 'Mapa vazio',
          mensagem:
              'Ainda não há posições salvas. Inicie a coleta e volte '
              'aqui para ver os marcadores.',
          textoBotao: 'Atualizar',
          aoPressionar: _carregar,
        ),
      );
    }
    return MapaLocalizacoes(localizacoes: localizacoes, cache: _cache);
  }
}
