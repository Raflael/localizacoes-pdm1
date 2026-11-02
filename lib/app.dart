import 'package:flutter/material.dart';

import 'features/localizacoes/presentation/screens/tela_coleta.dart';
import 'tema.dart';

class AppLocalizacoes extends StatelessWidget {
  const AppLocalizacoes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localizações',
      debugShowCheckedModeBanner: false,
      theme: criarTema(),
      home: const TelaColeta(),
    );
  }
}
