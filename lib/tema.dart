import 'package:flutter/material.dart';

/// Paleta de "caderno de campo": papel, tinta, verde-musgo e o vermelho
/// usado para marcar a localização mais recente.
abstract final class Cores {
  static const papel = Color(0xFFF3EDE0);
  static const folha = Color(0xFFFBF8F1);
  static const tinta = Color(0xFF2A2722);
  static const tintaSuave = Color(0xFF6E665A);
  static const linha = Color(0xFFDDD3C0);
  static const musgo = Color(0xFF3F5B45);
  static const vermelho = Color(0xFFB83A2B);
}

/// Títulos em serifa (Fraunces). É uma fonte variável: o peso e o tamanho
/// óptico vêm dos eixos `wght` e `opsz`.
TextStyle estiloTitulo(double tamanho, {Color cor = Cores.tinta}) {
  return TextStyle(
    fontFamily: 'Fraunces',
    fontSize: tamanho,
    height: 1.1,
    color: cor,
    fontVariations: const [
      FontVariation('wght', 560),
      FontVariation('opsz', 72),
      FontVariation('SOFT', 50),
    ],
  );
}

/// Dados e rótulos em monoespaçada (IBM Plex Mono): os números se alinham.
TextStyle estiloDados({
  double tamanho = 13,
  Color cor = Cores.tinta,
  FontWeight peso = FontWeight.w400,
  double espacamento = 0,
}) {
  return TextStyle(
    fontFamily: 'PlexMono',
    fontSize: tamanho,
    color: cor,
    fontWeight: peso,
    letterSpacing: espacamento,
  );
}

ThemeData criarTema() {
  final esquema = ColorScheme.fromSeed(seedColor: Cores.musgo).copyWith(
    primary: Cores.musgo,
    onPrimary: Cores.folha,
    error: Cores.vermelho,
    surface: Cores.papel,
    onSurface: Cores.tinta,
    onSurfaceVariant: Cores.tintaSuave,
    outline: Cores.linha,
  );
  final formaBotao = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  return ThemeData(
    colorScheme: esquema,
    scaffoldBackgroundColor: Cores.papel,
    appBarTheme: AppBarTheme(
      backgroundColor: Cores.papel,
      foregroundColor: Cores.tinta,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: estiloTitulo(24),
    ),
    cardTheme: CardThemeData(
      color: Cores.folha,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Cores.linha),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: formaBotao,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: formaBotao,
        foregroundColor: Cores.tinta,
        side: const BorderSide(color: Cores.tinta),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Cores.linha, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: Cores.folha,
      titleTextStyle: estiloTitulo(22),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Cores.papel,
      showDragHandle: true,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Cores.tinta,
    ),
  );
}
