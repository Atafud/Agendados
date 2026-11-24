import 'package:agendados/main.dart';
import 'package:agendados/model.dart';
import 'package:agendados/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app({Brightness brightness = Brightness.light, bool highContrast = false}) => MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        platformBrightness: brightness,
        highContrast: highContrast,
      ),
      child: AgendadosApp(model: AgendaModel(now: DateTime(2026, 11, 17))),
    );

/// La pantalla de prueba por defecto es de 800x600: con una lista larga las tarjetas
/// de abajo quedan fuera y no se pueden tocar. Usamos un móvil alto.
void prueba(String descripcion, Future<void> Function(WidgetTester) cuerpo) =>
    testWidgets(descripcion, (t) async {
      await t.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await cuerpo(t);
    });

/// Casilla de «Comprar cuaderno» (tercera tarjeta de la agenda).
Finder get casilla => find.byType(Checkbox).at(2);

AppColors coloresActuales(WidgetTester t) =>
    Theme.of(t.element(find.byType(Scaffold).first)).extension<AppColors>()!;

/// Ratio de contraste WCAG entre dos colores.
double contraste(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final vibraciones = <String>[];

  setUp(() {
    vibraciones.clear();
    themeMode.value = ThemeMode.system;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') vibraciones.add(call.arguments as String);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    themeMode.value = ThemeMode.system;
  });

  group('Paletas: contraste', () {
    final paletas = {
      'claro': AppColors.light,
      'oscuro': AppColors.dark,
      'alto contraste claro': AppColors.highContrastLight,
      'alto contraste oscuro': AppColors.highContrastDark,
    };
    paletas.forEach((nombre, c) {
      test('$nombre: todos los pares texto/fondo llegan a 4,5:1', () {
        final pares = {
          'texto/fondo': contraste(c.text, c.surface),
          'texto secundario/fondo': contraste(c.textSecondary, c.surface),
          'primario/fondo': contraste(c.primary, c.surface),
          'texto sobre primario': contraste(c.onPrimary, c.primary),
          'texto/seleccionado': contraste(c.text, c.selectedBg),
          'error/fondo': contraste(c.error, c.surface),
          'urgente/fondo': contraste(c.urgent, c.surface),
          'éxito/fondo de éxito': contraste(c.success, c.successBg),
          'deshabilitado/fondo': contraste(c.disabled, c.surface),
        };
        pares.forEach((par, ratio) => expect(ratio, greaterThanOrEqualTo(4.5), reason: '$nombre · $par = ${ratio.toStringAsFixed(2)}'));
      });
    });

    test('alto contraste: texto principal llega a 7:1', () {
      for (final c in [AppColors.highContrastLight, AppColors.highContrastDark]) {
        expect(contraste(c.text, c.surface), greaterThanOrEqualTo(7));
        expect(contraste(c.textSecondary, c.surface), greaterThanOrEqualTo(7));
      }
    });
  });

  group('Tema según el sistema', () {
    prueba('claro por defecto', (t) async {
      await t.pumpWidget(app());
      expect(coloresActuales(t).surface, AppColors.light.surface);
    });

    prueba('oscuro si el sistema está en oscuro', (t) async {
      await t.pumpWidget(app(brightness: Brightness.dark));
      expect(coloresActuales(t).surface, AppColors.dark.surface);
    });

    prueba('alto contraste claro', (t) async {
      await t.pumpWidget(app(highContrast: true));
      expect(coloresActuales(t).primary, AppColors.highContrastLight.primary);
    });

    prueba('alto contraste oscuro', (t) async {
      await t.pumpWidget(app(brightness: Brightness.dark, highContrast: true));
      expect(coloresActuales(t).surface, AppColors.highContrastDark.surface);
    });
  });

  group('Botón de tema', () {
    prueba('alterna claro y oscuro y cambia su nombre', (t) async {
      await t.pumpWidget(app());
      expect(find.byTooltip('Cambiar a tema oscuro'), findsOneWidget);
      await t.tap(find.byTooltip('Cambiar a tema oscuro'));
      await t.pumpAndSettle();
      expect(themeMode.value, ThemeMode.dark);
      expect(coloresActuales(t).surface, AppColors.dark.surface);
      expect(find.byTooltip('Cambiar a tema claro'), findsOneWidget);
      await t.tap(find.byTooltip('Cambiar a tema claro'));
      await t.pumpAndSettle();
      expect(themeMode.value, ThemeMode.light);
      expect(coloresActuales(t).surface, AppColors.light.surface);
    });

    prueba('forzar claro gana al sistema oscuro', (t) async {
      themeMode.value = ThemeMode.light;
      await t.pumpWidget(app(brightness: Brightness.dark));
      expect(coloresActuales(t).surface, AppColors.light.surface);
    });

    for (final modo in ['claro', 'oscuro']) {
      prueba('tema $modo: objetivos táctiles, etiquetas y contraste', (t) async {
        final h = t.ensureSemantics();
        themeMode.value = modo == 'claro' ? ThemeMode.light : ThemeMode.dark;
        await t.pumpWidget(app());
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(t, meetsGuideline(textContrastGuideline));
        h.dispose();
      });
    }
  });

  group('Vibración', () {
    Future<void> marcarHecha(WidgetTester t) async {
      await t.tap(casilla);
      await t.pumpAndSettle();
    }

    prueba('marcar como hecha vibra suave una vez', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(app());
      await marcarHecha(t);
      expect(vibraciones, ['HapticFeedbackType.lightImpact']);
      h.dispose();
    });

    prueba('volver a pendiente no vibra', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(app());
      await marcarHecha(t);
      vibraciones.clear();
      await t.tap(casilla);
      await t.pumpAndSettle();
      expect(vibraciones, isEmpty);
      h.dispose();
    });

    prueba('guardar una actividad vibra suave', (t) async {
      await t.pumpWidget(app());
      await t.tap(find.text('Añadir actividad'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, 'Cita dentista');
      await t.tap(find.text('Guardar actividad'));
      await t.pumpAndSettle();
      expect(vibraciones, ['HapticFeedbackType.lightImpact']);
    });

    prueba('guardar con errores no vibra', (t) async {
      await t.pumpWidget(app());
      await t.tap(find.text('Añadir actividad'));
      await t.pumpAndSettle();
      await t.tap(find.text('Guardar actividad'));
      await t.pumpAndSettle();
      expect(vibraciones, isEmpty);
    });

    Future<void> abrirDetalleYEliminar(WidgetTester t) async {
      await t.tap(find.text('Comprar cuaderno'));
      await t.pumpAndSettle();
      await t.tap(find.text('Eliminar'));
      await t.pumpAndSettle();
    }

    prueba('confirmar el borrado vibra medio', (t) async {
      await t.pumpWidget(app());
      await abrirDetalleYEliminar(t);
      await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Eliminar')));
      await t.pumpAndSettle();
      expect(vibraciones, ['HapticFeedbackType.mediumImpact']);
      expect(find.text('Eliminada: Comprar cuaderno'), findsOneWidget);
    });

    prueba('cancelar el borrado no vibra y conserva la actividad', (t) async {
      await t.pumpWidget(app());
      await abrirDetalleYEliminar(t);
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(vibraciones, isEmpty);
      expect(find.text('Comprar cuaderno'), findsWidgets);
    });
  });

  group('Anuncios de cambios', () {
    prueba('marcar como hecha y volver a pendiente avisan', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(app());
      await t.tap(casilla);
      await t.pumpAndSettle();
      expect(find.text('Hecha: Comprar cuaderno'), findsOneWidget);
      await t.tap(casilla);
      await t.pumpAndSettle();
      expect(find.text('Pendiente: Comprar cuaderno'), findsOneWidget);
      expect(find.text('Hecha: Comprar cuaderno'), findsNothing);
      h.dispose();
    });

    prueba('el aviso aparece también desde Detalle', (t) async {
      await t.pumpWidget(app());
      await t.tap(find.text('Comprar cuaderno'));
      await t.pumpAndSettle();
      await t.tap(find.text('Marcar como hecha'));
      await t.pumpAndSettle();
      expect(find.text('Hecha: Comprar cuaderno'), findsOneWidget);
    });

    prueba('marcar hecha desde Avisos pendientes avisa', (t) async {
      await t.pumpWidget(app());
      await t.tap(find.textContaining('Avisos pendientes').first);
      await t.pumpAndSettle();
      await t.tap(find.textContaining('Hecha: Entrega de práctica'));
      await t.pumpAndSettle();
      expect(find.text('Hecha: Entrega de práctica'), findsOneWidget);
    });

    prueba('posponer 10 minutos avisa', (t) async {
      await t.pumpWidget(app());
      await t.tap(find.textContaining('Avisos pendientes').first);
      await t.pumpAndSettle();
      await t.tap(find.textContaining('Posponer 10 minutos: Entrega de práctica'));
      await t.pumpAndSettle();
      expect(find.text('Pospuesta 10 minutos: Entrega de práctica'), findsOneWidget);
    });

    prueba('guardar con errores avisa cada vez que se pulsa', (t) async {
      await t.pumpWidget(app());
      await t.tap(find.text('Añadir actividad'));
      await t.pumpAndSettle();
      const aviso = 'No se guardó. Corrige los campos con error.';
      await t.tap(find.text('Guardar actividad'));
      await t.pumpAndSettle();
      expect(find.text(aviso), findsOneWidget);
      // Se cierra el aviso y se vuelve a pulsar con el mismo error en pantalla.
      ScaffoldMessenger.of(t.element(find.byType(Scaffold).last)).clearSnackBars();
      await t.pumpAndSettle();
      expect(find.text(aviso), findsNothing);
      await t.tap(find.text('Guardar actividad'));
      await t.pumpAndSettle();
      expect(find.text(aviso), findsOneWidget);
      expect(find.textContaining('Falta el título'), findsOneWidget);
    });

    prueba('guardar bien muestra su mensaje y no el de error', (t) async {
      await t.pumpWidget(app());
      await t.tap(find.text('Añadir actividad'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, 'Cita dentista');
      await t.tap(find.text('Guardar actividad'));
      await t.pumpAndSettle();
      expect(find.textContaining('Guardada: Cita dentista'), findsOneWidget);
      expect(find.textContaining('No se guardó'), findsNothing);
    });
  });
}
