import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'model.dart';
import 'screens.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // En Flutter web el árbol semántico está apagado hasta que el usuario pulsa
  // «Enable accessibility». Lo activamos desde el inicio para lectores de pantalla.
  SemanticsBinding.instance.ensureSemantics();
  runApp(AgendadosApp(model: AgendaModel()));
}

class AgendadosApp extends StatelessWidget {
  const AgendadosApp({super.key, required this.model});
  final AgendaModel model;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Agendados',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        // El sistema elige: claro/oscuro y, si el usuario activó alto contraste, su variante.
        theme: buildTheme(AppColors.light),
        darkTheme: buildTheme(AppColors.dark, brightness: Brightness.dark),
        highContrastTheme: buildTheme(AppColors.highContrastLight),
        highContrastDarkTheme: buildTheme(AppColors.highContrastDark, brightness: Brightness.dark),
        locale: const Locale('es'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es'), Locale('en')],
        home: HomeShell(model: model),
        // NO se fija textScaler: se respeta el tamaño de fuente del sistema.
      ));
}
