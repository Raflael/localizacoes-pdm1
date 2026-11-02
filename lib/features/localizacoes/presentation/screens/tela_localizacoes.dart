import 'package:flutter/material.dart';

import '../../../../tema.dart';
import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../widgets/aviso_tela.dart';
import '../widgets/item_localizacao.dart';

/// Histórico: as 100 localizações mais recentes, da mais nova para a mais
/// antiga, com opção de atualizar e de apagar tudo.
class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({super.key, required this.coletaAtiva});

  /// Usado só para avisar, na confirmação, que a coleta continua gravando.
  final bool coletaAtiva;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  final _repositorio = RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = [];
  int _total = 0;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Lê o banco de novo. Não mexe na coleta, que segue na tela inicial.
  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final registros = await _repositorio.buscarRecentes();
      final total = await _repositorio.contar();
      if (!mounted) return;
      setState(() {
        _localizacoes = registros;
        _total = total;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível ler o banco de dados.';
        _carregando = false;
      });
    }
  }

  Future<void> _confirmarLimpeza() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, color: Cores.vermelho),
        title: const Text('Limpar histórico?'),
        content: Text(
          [
            'Todos os $_total registros serão apagados, inclusive os que não '
                'aparecem na lista.',
            'Esta operação é permanente e não pode ser desfeita.',
            if (widget.coletaAtiva)
              'A coleta está ativa: novos registros continuarão sendo salvos.',
          ].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Cores.vermelho,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      final apagados = await _repositorio.excluirTodos();
      if (!mounted) return;
      await _carregar();
      if (!mounted) return;
      _avisar('Histórico limpo: $apagados registros apagados.');
    } catch (_) {
      if (!mounted) return;
      _avisar('Não foi possível limpar o histórico. Tente novamente.');
    }
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: _carregando || _total == 0 ? null : _confirmarLimpeza,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_carregando && _localizacoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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

    // RefreshIndicator: puxar a lista para baixo também atualiza.
    return RefreshIndicator(
      onRefresh: _carregar,
      child: _localizacoes.isEmpty
          ? ListView(
              children: const [
                AvisoTela(
                  icone: Icons.explore_outlined,
                  titulo: 'Nenhuma localização',
                  mensagem:
                      'Inicie a coleta na tela inicial. As posições aparecem '
                      'aqui, da mais recente para a mais antiga.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _localizacoes.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, indice) {
                if (indice == 0) return _cabecalho();
                return ItemLocalizacao(
                  localizacao: _localizacoes[indice - 1],
                  maisRecente: indice == 1,
                );
              },
            ),
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 4),
      child: Text(
        'Mostrando ${_localizacoes.length} de $_total registros'
        '${widget.coletaAtiva ? ' · coleta ativa' : ''}',
        style: estiloDados(tamanho: 11, cor: Cores.tintaSuave, espacamento: 1),
      ),
    );
  }
}
