import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../tema.dart';
import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import '../widgets/item_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

/// Tela inicial: liga e desliga a coleta e leva às outras telas.
///
/// A assinatura do stream mora aqui. Como esta tela fica sempre na base da
/// navegação, a coleta continua enquanto o usuário abre o histórico ou o mapa.
class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  final _servico = ServicoLocalizacao();
  final _repositorio = RepositorioLocalizacoes();

  StreamSubscription<Position>? _assinatura;

  /// Verdadeiro enquanto checa GPS e permissões (impede um segundo toque).
  bool _iniciando = false;

  /// Verdadeiro enquanto uma posição está sendo gravada no banco.
  bool _gravando = false;

  int _salvasNestaColeta = 0;
  Localizacao? _ultima;

  bool get _coletando => _assinatura != null;

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  Future<void> _iniciarColeta() async {
    // Nunca abre uma segunda assinatura.
    if (_coletando || _iniciando) return;
    setState(() => _iniciando = true);

    try {
      final situacao = await _servico.verificarPermissao();
      if (!mounted) return;
      if (situacao != SituacaoPermissao.concedida) {
        _orientar(situacao);
        return;
      }

      final notificacaoPermitida = await _servico.pedirPermissaoNotificacao();
      if (!mounted) return;
      if (!notificacaoPermitida) {
        _avisar(
          'Sem permissão de notificações o aviso da coleta não aparece, '
          'mas as posições continuam sendo salvas.',
        );
      }

      setState(() {
        _salvasNestaColeta = 0;
        _assinatura = _servico.posicoes().listen(
          _salvarPosicao,
          onError: _aoFalharLocalizacao,
        );
      });
    } catch (_) {
      if (mounted) _avisar('Não foi possível iniciar a coleta.');
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  Future<void> _pararColeta() async {
    final assinatura = _assinatura;
    if (assinatura == null) return;

    setState(() => _assinatura = null);
    // Cancelar a assinatura também encerra o serviço e a notificação.
    await assinatura.cancel();
    if (!mounted) return;
    final n = _salvasNestaColeta;
    _avisar(
      'Coleta encerrada. $n ${n == 1 ? 'posição salva' : 'posições salvas'}.',
    );
  }

  Future<void> _salvarPosicao(Position posicao) async {
    // Se a gravação anterior ainda não terminou, esta posição é ignorada.
    // Com uma leitura a cada 20 s isso é raro, mas evita gravar em paralelo.
    if (_gravando) return;
    _gravando = true;

    final localizacao = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: posicao.timestamp.toUtc(),
    );

    try {
      await _repositorio.inserir(localizacao);
      if (!mounted) return;
      setState(() {
        _ultima = localizacao;
        _salvasNestaColeta++;
      });
    } catch (_) {
      if (mounted) _avisar('Falha ao salvar a posição no banco.');
    } finally {
      _gravando = false;
    }
  }

  void _aoFalharLocalizacao(Object erro) {
    if (!mounted) return;
    final String mensagem;
    if (erro is LocationServiceDisabledException) {
      mensagem = 'O GPS foi desligado e a coleta foi interrompida.';
    } else if (erro is PermissionDeniedException) {
      mensagem =
          'A permissão de localização foi retirada. Coleta interrompida.';
    } else {
      mensagem = 'Erro ao obter a localização. Coleta interrompida.';
    }
    _assinatura?.cancel();
    setState(() => _assinatura = null);
    _avisar(mensagem);
  }

  /// Explica ao usuário o que fazer quando a coleta não pode começar.
  void _orientar(SituacaoPermissao situacao) {
    switch (situacao) {
      case SituacaoPermissao.gpsDesligado:
        _avisar(
          'A localização do aparelho está desligada.',
          acao: SnackBarAction(
            label: 'Ligar',
            onPressed: _servico.abrirConfiguracoesGps,
          ),
        );
      case SituacaoPermissao.negada:
        _avisar(
          'O app precisa da permissão de localização para coletar. '
          'Toque em Iniciar coleta e escolha "Permitir".',
        );
      case SituacaoPermissao.negadaPermanentemente:
        _mostrarDialogoConfiguracoes();
      case SituacaoPermissao.concedida:
        break;
    }
  }

  Future<void> _mostrarDialogoConfiguracoes() async {
    final abrir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_off_outlined),
        title: const Text('Permissão bloqueada'),
        content: const Text(
          'A localização foi negada e o Android não vai perguntar de novo.\n\n'
          'Nas configurações, abra Permissões › Localização e escolha '
          '"Permitir durante o uso do app".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Abrir configurações'),
          ),
        ],
      ),
    );
    if (abrir == true) await _servico.abrirConfiguracoesApp();
  }

  void _avisar(String mensagem, {SnackBarAction? acao}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem), action: acao));
  }

  void _abrir(Widget tela) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _ultima;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            Text(
              'CADERNO DE CAMPO',
              style: estiloDados(
                tamanho: 11,
                cor: Cores.tintaSuave,
                espacamento: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text('Localizações', style: estiloTitulo(40)),
            const SizedBox(height: 8),
            const Text(
              'Uma posição a cada 20 segundos, guardada só no aparelho.',
              style: TextStyle(color: Cores.tintaSuave, height: 1.4),
            ),
            const SizedBox(height: 24),
            _PainelStatus(
              coletando: _coletando,
              iniciando: _iniciando,
              salvas: _salvasNestaColeta,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _coletando || _iniciando ? null : _iniciarColeta,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Iniciar coleta'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _coletando ? _pararColeta : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Parar coleta'),
                  ),
                ),
              ],
            ),
            if (ultima != null) ...[
              const SizedBox(height: 28),
              const _Rotulo('ÚLTIMA POSIÇÃO SALVA'),
              ItemLocalizacao(localizacao: ultima, maisRecente: true),
            ],
            const SizedBox(height: 28),
            const _Rotulo('REGISTROS'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _BotaoMenu(
                    icone: Icons.format_list_bulleted,
                    titulo: 'Consultar histórico',
                    descricao: 'As 100 posições mais recentes',
                    aoTocar: () =>
                        _abrir(TelaLocalizacoes(coletaAtiva: _coletando)),
                  ),
                  const Divider(),
                  _BotaoMenu(
                    icone: Icons.map_outlined,
                    titulo: 'Ver mapa',
                    descricao: 'Marcadores sobre as ruas',
                    aoTocar: () => _abrir(const TelaMapa()),
                  ),
                  const Divider(),
                  _BotaoMenu(
                    icone: Icons.admin_panel_settings_outlined,
                    titulo: 'Configurações de permissão',
                    descricao: 'Localização e notificações do app',
                    aoTocar: _servico.abrirConfiguracoesApp,
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

/// Cartão com o estado da coleta e quantas posições foram salvas.
class _PainelStatus extends StatelessWidget {
  const _PainelStatus({
    required this.coletando,
    required this.iniciando,
    required this.salvas,
  });

  final bool coletando;
  final bool iniciando;
  final int salvas;

  @override
  Widget build(BuildContext context) {
    final String titulo;
    final String detalhe;
    if (coletando) {
      titulo = 'Coletando';
      detalhe = 'Continua com o app minimizado. A notificação fica visível.';
    } else if (iniciando) {
      titulo = 'Preparando…';
      detalhe = 'Verificando o GPS e as permissões.';
    } else {
      titulo = 'Coleta parada';
      detalhe = 'Toque em Iniciar coleta para registrar sua posição.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _IndicadorColeta(ativo: coletando),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: estiloTitulo(22)),
                  const SizedBox(height: 4),
                  Text(
                    detalhe,
                    style: const TextStyle(
                      color: Cores.tintaSuave,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$salvas', style: estiloTitulo(28)),
                Text(
                  'salvas',
                  style: estiloDados(tamanho: 11, cor: Cores.tintaSuave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bolinha que pulsa enquanto a coleta está ativa.
class _IndicadorColeta extends StatefulWidget {
  const _IndicadorColeta({required this.ativo});

  final bool ativo;

  @override
  State<_IndicadorColeta> createState() => _IndicadorColetaState();
}

class _IndicadorColetaState extends State<_IndicadorColeta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.ativo) _pulso.repeat();
  }

  @override
  void didUpdateWidget(_IndicadorColeta anterior) {
    super.didUpdateWidget(anterior);
    if (widget.ativo && !_pulso.isAnimating) {
      _pulso.repeat();
    } else if (!widget.ativo) {
      _pulso.reset();
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.ativo ? Cores.musgo : Cores.linha;

    return SizedBox(
      width: 32,
      height: 32,
      child: AnimatedBuilder(
        animation: _pulso,
        builder: (context, _) {
          final t = _pulso.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.ativo)
                Container(
                  width: 14 + 18 * t,
                  height: 14 + 18 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Cores.musgo.withValues(alpha: 0.35 * (1 - t)),
                  ),
                ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        texto,
        style: estiloDados(tamanho: 11, cor: Cores.tintaSuave, espacamento: 2),
      ),
    );
  }
}

class _BotaoMenu extends StatelessWidget {
  const _BotaoMenu({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.aoTocar,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: aoTocar,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icone, color: Cores.musgo),
      title: Text(titulo, style: estiloTitulo(17)),
      subtitle: Text(
        descricao,
        style: const TextStyle(color: Cores.tintaSuave, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Cores.tintaSuave),
    );
  }
}
