import 'package:sqflite/sqflite.dart';

import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';

/// Único lugar do app que fala SQL. As telas só recebem objetos [Localizacao].
class RepositorioLocalizacoes {
  RepositorioLocalizacoes({BancoLocalizacoes? banco})
    : _banco = banco ?? BancoLocalizacoes.instancia;

  final BancoLocalizacoes _banco;

  static const _tabela = BancoLocalizacoes.tabela;

  /// Grava uma posição e devolve o id gerado.
  Future<int> inserir(Localizacao localizacao) async {
    final banco = await _banco.abrir();
    return banco.insert(_tabela, localizacao.paraMapa());
  }

  /// As [limite] posições mais recentes, da mais nova para a mais antiga.
  /// O limite vale só para a consulta: nada antigo é apagado.
  Future<List<Localizacao>> buscarRecentes({int limite = 100}) async {
    final banco = await _banco.abrir();
    final linhas = await banco.query(
      _tabela,
      orderBy: 'instante DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Localizacao.deMapa).toList();
  }

  /// Quantidade total de registros salvos (inclusive os fora das 100).
  Future<int> contar() async {
    final banco = await _banco.abrir();
    final resultado = await banco.rawQuery('SELECT COUNT(*) FROM $_tabela');
    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  /// Apaga todas as linhas. A tabela e o arquivo do banco continuam existindo.
  /// Devolve quantos registros foram removidos.
  Future<int> excluirTodos() async {
    final banco = await _banco.abrir();
    return banco.delete(_tabela);
  }
}
