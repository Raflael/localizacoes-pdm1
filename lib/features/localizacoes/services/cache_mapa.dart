import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Prepara o cache das imagens (tiles) do mapa numa pasta privada do app.
///
/// O cache do flutter_map respeita os cabeçalhos HTTP de validade enviados
/// pelo OpenStreetMap, como pede a política de uso dos tiles: uma imagem só é
/// baixada de novo quando venceu, e nada é baixado em massa.
class CacheMapa {
  static const _tamanhoMaximo = 100 * 1024 * 1024; // 100 MB

  /// Devolve o provedor de cache, ou `null` se a pasta não puder ser usada
  /// (nesse caso o mapa funciona normalmente, só que sem cache).
  static Future<MapCachingProvider?> preparar() async {
    try {
      final pastaPrivada = await getApplicationCacheDirectory();
      return BuiltInMapCachingProvider.getOrCreateInstance(
        cacheDirectory: join(pastaPrivada.path, 'mapa'),
        maxCacheSize: _tamanhoMaximo,
      );
    } catch (_) {
      return null;
    }
  }
}
