# Agendados (Grupo O) — app Flutter v1, semana 5

Agenda + tareas + recordatorios accesibles. Datos locales/simulados (sin backend).

    flutter pub get
    flutter analyze
    flutter test
    flutter run

Estructura: `lib/theme.dart` (paleta medida), `model.dart` (estado), `widgets.dart` (componentes
con semántica), `screens.dart` (P01-P06). Estado: sin plugin de notificaciones; el aviso (R3)
se simula en la pantalla Avisos pendientes.

## Si falta la carpeta de plataforma (android/, ios/, web/)
Este paquete solo trae `lib/`, `test/` y `pubspec.yaml`. En una carpeta vacía:

    flutter create --org es.grupoo --project-name agendados .
    # y luego sustituir lib/, test/ y pubspec.yaml por los de este paquete
    flutter pub get && flutter run -d chrome   # o un emulador Android
