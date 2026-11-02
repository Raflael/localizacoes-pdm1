import 'package:flutter/material.dart';

import '../../../../tema.dart';

/// Mensagem centralizada para estados de erro ou de lista vazia,
/// com um botão opcional (ex.: "Tentar novamente").
class AvisoTela extends StatelessWidget {
  const AvisoTela({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.textoBotao,
    this.aoPressionar,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? textoBotao;
  final VoidCallback? aoPressionar;

  @override
  Widget build(BuildContext context) {
    final textoBotao = this.textoBotao;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 40, color: Cores.tintaSuave),
          const SizedBox(height: 16),
          Text(titulo, style: estiloTitulo(22), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Cores.tintaSuave, height: 1.4),
          ),
          if (textoBotao != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: aoPressionar,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: Text(textoBotao),
            ),
          ],
        ],
      ),
    );
  }
}
