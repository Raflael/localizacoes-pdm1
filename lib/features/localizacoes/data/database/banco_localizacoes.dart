import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Abre o arquivo `localizacoes.db` e cria a tabela na primeira execução.
///
/// Existe uma única instância no app ([instancia]) para reaproveitar a mesma
/// conexão em todas as telas.
class BancoLocalizacoes {
  BancoLocalizacoes._();

  static final BancoLocalizacoes instancia = BancoLocalizacoes._();

  static const nomeArquivo = 'localizacoes.db';
  static const versao = 1;
  static const tabela = 'localizacoes';

  Database? _banco;

  /// Devolve a conexão aberta, abrindo o banco só na primeira vez.
  ///
  /// Se a abertura falhar, [_banco] continua nulo e a próxima chamada tenta
  /// abrir de novo, em vez de guardar o erro para sempre.
  Future<Database> abrir() async {
    final aberto = _banco;
    if (aberto != null && aberto.isOpen) return aberto;

    final caminho = join(await getDatabasesPath(), nomeArquivo);
    final banco = await openDatabase(
      caminho,
      version: versao,
      onCreate: _criarTabelas,
    );
    _banco = banco;
    return banco;
  }

  Future<void> _criarTabelas(Database banco, int versao) async {
    await banco.execute('''
      CREATE TABLE $tabela (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        precisao REAL NOT NULL,
        instante TEXT NOT NULL
      )
    ''');
  }
}
