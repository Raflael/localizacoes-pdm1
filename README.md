# Localizações — Caderno de Campo

Atividade 1 — Coleta e visualização de localizações
Programação para Dispositivos Móveis I · Prof. Arley · Fatec Jacareí — DSM

**Integrante:** Rafael Medeiros — RA 2581392513017

Aplicativo Flutter para Android que coleta a posição do aparelho a cada 20 segundos,
guarda tudo num banco SQLite local e mostra os registros numa lista e num mapa interativo.

## Funcionalidades

- **Tela inicial (coleta):** botões *Iniciar coleta*, *Parar coleta*, *Consultar histórico*,
  *Ver mapa* e *Configurações de permissão*. Antes de iniciar, o app verifica se o GPS está
  ligado e pede a permissão de localização; se for negada, explica o que fazer e, quando o
  Android não pergunta mais, leva às configurações do app.
- **Coleta contínua por stream** (`Geolocator.getPositionStream`), alta precisão, intervalo
  solicitado de 20 s. No Android roda num **serviço em primeiro plano** com notificação fixa,
  então continua ao trocar de tela e ao minimizar. *Parar coleta* cancela a assinatura, o que
  encerra o serviço e a notificação.
- **Histórico:** as 100 posições mais recentes (da mais nova para a mais antiga), com data e hora
  locais, latitude/longitude com 6 casas e precisão em metros com 1 casa. Atualiza pelo botão
  ou puxando a lista, sem interromper a coleta. *Limpar histórico* pede confirmação e apaga
  **todos** os registros, inclusive os anteriores aos 100 exibidos.
- **Mapa:** ruas do OpenStreetMap, um marcador por posição, a mais recente em **vermelho**,
  trajeto tracejado, enquadramento automático ao carregar, botão *Enquadrar* e botão
  *Atualizar*. Tocar num marcador mostra a ficha daquela posição.
- **Ícone próprio** (trilha de pontos chegando ao alfinete vermelho), adaptativo no Android 8+.

## Como executar

```bash
flutter pub get
flutter run            # com um celular Android conectado
flutter build apk      # gera build/app/outputs/flutter-apk/app-release.apk
```

Plataforma escolhida: **Android**.

## Estrutura

```
lib/
├── main.dart                         inicializa o Flutter e roda o app
├── app.dart                          MaterialApp e tela inicial
├── tema.dart                         cores e fontes (visual de caderno de campo)
└── features/localizacoes/
    ├── models/localizacao.dart       registro tipado + conversão para/de mapa
    ├── data/
    │   ├── database/banco_localizacoes.dart        abre o banco e cria a tabela
    │   └── repositories/repositorio_localizacoes.dart   inserir, consultar, contar, excluir
    ├── services/
    │   ├── servico_localizacao.dart  GPS, permissões, stream e configurações
    │   └── cache_mapa.dart           pasta privada para o cache das imagens do mapa
    └── presentation/
        ├── screens/                  tela_coleta, tela_localizacoes, tela_mapa
        └── widgets/                  item_localizacao, mapa_localizacoes, aviso_tela
```

Arquivos além da estrutura sugerida: `tema.dart` (cores e fontes usadas por todas as telas)
e `aviso_tela.dart` (mensagem de erro/lista vazia reaproveitada no histórico e no mapa).

## Banco de dados

Arquivo `localizacoes.db`, tabela `localizacoes`:

| Coluna    | Tipo    | Observação                               |
|-----------|---------|------------------------------------------|
| id        | INTEGER | chave primária, autoincremento           |
| latitude  | REAL    | obrigatória                              |
| longitude | REAL    | obrigatória                              |
| precisao  | REAL    | obrigatória, em metros                   |
| instante  | TEXT    | obrigatória, UTC em ISO 8601             |

O limite de 100 vale só para as consultas; nada é apagado automaticamente. A limpeza usa
`DELETE` sem condição, então a tabela e o arquivo continuam existindo. Nenhum banco com
coordenadas está no repositório (`*.db` no `.gitignore`).

## Decisões

- **Sem duplicar a coleta:** *Iniciar* fica desabilitado enquanto há assinatura ativa ou
  enquanto as permissões estão sendo verificadas; *Parar* só fica habilitado durante a coleta.
- **Sem gravações sobrepostas:** se uma posição chegar enquanto a anterior ainda está sendo
  gravada, ela é ignorada (com 20 s entre leituras isso praticamente não acontece).
- **Permissão de notificação (Android 13+):** pedida ao iniciar, para que a notificação do
  serviço apareça. Se for negada a coleta funciona do mesmo jeito e o app avisa.
- **Mapa e OpenStreetMap:** o app se identifica (`userAgentPackageName`), mostra a atribuição
  “© OpenStreetMap contributors” e usa o cache do `flutter_map`, que respeita os cabeçalhos de
  validade dos tiles. O cache fica na pasta de cache privada do app, limitado a 100 MB.
- **Mounted e recursos:** toda atualização de tela depois de `await` confere `mounted`; a
  assinatura do stream, o `MapController` e o `AnimationController` são liberados no `dispose`.

## Dependências

`geolocator` (GPS, permissões e stream), `permission_handler` (notificação no Android 13+),
`sqflite` + `path` (banco), `flutter_map` + `latlong2` (mapa), `path_provider` (pasta do cache),
`intl` (data e hora). Fontes Fraunces e IBM Plex Mono (licença OFL, em `assets/fonts`).
