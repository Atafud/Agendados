import 'package:agendados/main.dart';
import 'package:agendados/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app({double scale = 1}) => MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale), size: const Size(390, 844)),
      child: AgendadosApp(model: AgendaModel(now: DateTime(2026, 11, 17))),
    );

void main() {
  testWidgets('P01: tamaño táctil, etiquetas y contraste (RNF-A01, A02, A03)', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(app());
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(t, meetsGuideline(textContrastGuideline));
    h.dispose();
  });

  testWidgets('P01 con texto al 200 % sigue sin desbordar (RNF-A04)', (t) async {
    await t.pumpWidget(app(scale: 2));
    expect(tester(t), isNull);
    expect(find.text('Añadir actividad'), findsOneWidget);
  });

  testWidgets('R1: crear solo con título y ver error sin perder datos', (t) async {
    await t.pumpWidget(app());
    await t.tap(find.text('Añadir actividad'));
    await t.pumpAndSettle();
    await t.tap(find.text('Guardar actividad'));
    await t.pumpAndSettle();
    expect(find.textContaining('Falta el título'), findsOneWidget);
    await t.enterText(find.byType(TextFormField).first, 'Cita dentista');
    await t.tap(find.text('Guardar actividad'));
    await t.pumpAndSettle();
    expect(find.text('Cita dentista'), findsOneWidget);
  });

  testWidgets('R2: marcar hecha con una pulsación y semántica de la tarjeta', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(app());
    expect(find.bySemanticsLabel(RegExp('Marcar «Comprar cuaderno» como hecha')), findsOneWidget);
    await t.tap(find.bySemanticsLabel(RegExp('Marcar «Comprar cuaderno» como hecha')));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Volver a dejar pendiente «Comprar cuaderno»')), findsOneWidget);
    h.dispose();
  });

  testWidgets('R3: aviso pendiente se puede marcar como hecho', (t) async {
    await t.pumpWidget(app());
    await t.tap(find.textContaining('Avisos pendientes').first);
    await t.pumpAndSettle();
    expect(find.textContaining('Entrega de práctica'), findsWidgets);
    await t.tap(find.textContaining('Hecha: Entrega de práctica'));
    await t.pumpAndSettle();
    expect(find.text('No tienes avisos pendientes.'), findsOneWidget);
  });
}

Object? tester(WidgetTester t) => t.takeException();
