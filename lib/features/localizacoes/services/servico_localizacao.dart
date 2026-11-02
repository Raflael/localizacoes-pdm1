import 'dart:ui' show Color;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Resultado da verificação feita antes de começar a coleta.
enum SituacaoPermissao {
  concedida,
  gpsDesligado,
  negada,
  negadaPermanentemente,
}

/// Conversa com o GPS e com as permissões do sistema.
class ServicoLocalizacao {
  static const intervalo = Duration(seconds: 20);

  /// Confere se o GPS está ligado e se o app pode usar a localização,
  /// pedindo a permissão ao usuário quando ela ainda não foi decidida.
  Future<SituacaoPermissao> verificarPermissao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return SituacaoPermissao.gpsDesligado;
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    switch (permissao) {
      case LocationPermission.denied:
        return SituacaoPermissao.negada;
      case LocationPermission.deniedForever:
        return SituacaoPermissao.negadaPermanentemente;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        return SituacaoPermissao.concedida;
    }
  }

  /// No Android 13+ a notificação da coleta só aparece com esta permissão.
  /// Devolve `true` se ela foi concedida (em versões antigas, sempre `true`).
  Future<bool> pedirPermissaoNotificacao() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Stream contínuo de posições, em alta precisão, pedindo uma a cada 20 s.
  ///
  /// Com [ForegroundNotificationConfig] o Android roda a coleta num serviço em
  /// primeiro plano, com notificação fixa: ela continua com o app minimizado.
  /// O serviço termina quando a assinatura do stream é cancelada.
  Stream<Position> posicoes() {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: intervalo,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Coletando localização',
          notificationText:
              'Uma posição a cada 20 segundos. Abra o app para parar.',
          notificationChannelName: 'Coleta de localização',
          notificationIcon: AndroidResource(name: 'ic_notificacao_coleta'),
          color: Color(0xFF3F5B45), // verde do tema do app
          enableWakeLock: true,
          setOngoing: true,
        ),
      ),
    );
  }

  /// Abre a tela de permissões deste app nas configurações do Android.
  Future<bool> abrirConfiguracoesApp() => Geolocator.openAppSettings();

  /// Abre a tela do sistema para ligar o GPS.
  Future<bool> abrirConfiguracoesGps() => Geolocator.openLocationSettings();
}
