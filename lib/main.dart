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
  Widget build(BuildContext context) => MaterialApp(
        title: 'Agendados',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('es'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es'), Locale('en')],
        home: HomeShell(model: model),
        // NO se fija textScaler: se respeta el tamaño de fuente del sistema.
      );
}
