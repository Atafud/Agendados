import 'package:flutter/foundation.dart';

const _dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'septiembre', 'octubre', 'noviembre', 'diciembre'];

String two(int n) => n.toString().padLeft(2, '0');
String hora(int h, int m) => '${two(h)}:${two(m)}';
String mesAnio(DateTime d) => '${_meses[d.month - 1][0].toUpperCase()}${_meses[d.month - 1].substring(1)} ${d.year}';

/// Fecha completa y sin ambigüedad: "martes, 3 de noviembre".
String fechaLarga(DateTime d) => '${_dias[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}';
DateTime soloDia(DateTime d) => DateTime(d.year, d.month, d.day);
bool mismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class Activity {
  Activity({required this.id, required this.title, required this.date, this.hour = 9, this.minute = 0,
      this.reminderMinutes, this.urgent = false, this.done = false});
  final int id;
  String title;
  DateTime date;
  int hour;
  int minute;
  int? reminderMinutes; // minutos antes; null = sin aviso
  bool urgent;
  bool done;
  bool acknowledged = false; // aviso ya gestionado
  bool raised = false; // aviso recibido (simulado en v1)

  DateTime get when => DateTime(date.year, date.month, date.day, hour, minute);
  String get timeText => hora(hour, minute);
  String get reminderText => reminderMinutes == null
      ? 'Sin aviso'
      : reminderMinutes == 0 ? 'A la hora' : '$reminderMinutes minutos antes';
  String get stateText => done ? 'Hecha' : 'Pendiente';
}

class AgendaModel extends ChangeNotifier {
  AgendaModel({DateTime? now}) : today = soloDia(now ?? DateTime.now()) {
    selected = today;
    _seed();
  }
  final DateTime today;
  late DateTime selected;
  final List<Activity> items = [];
  int _next = 1;

  void _seed() {
    add('Clase de Accesibilidad', today, 9, 0, reminderMinutes: 30);
    add('Entrega de práctica', today, 11, 0, urgent: true, reminderMinutes: 60).raised = true;
    add('Comprar cuaderno', today, 13, 30, urgent: false);
  }

  Activity add(String title, DateTime date, int h, int m, {int? reminderMinutes, bool urgent = false}) {
    final a = Activity(id: _next++, title: title, date: soloDia(date), hour: h, minute: m,
        reminderMinutes: reminderMinutes, urgent: urgent);
    items.add(a);
    notifyListeners();
    return a;
  }

  List<Activity> forDay(DateTime d) =>
      (items.where((a) => mismoDia(a.date, d)).toList()..sort((a, b) => a.when.compareTo(b.when)));

  void selectDay(DateTime d) { selected = soloDia(d); notifyListeners(); }
  void shiftDay(int delta) => selectDay(selected.add(Duration(days: delta)));

  void toggleDone(Activity a) { a.done = !a.done; if (a.done) a.acknowledged = true; notifyListeners(); }
  void update() => notifyListeners();

  void remove(Activity a) {
    if (items.remove(a)) notifyListeners();
  }

  bool undoRemove(Activity a) {
    if (items.contains(a)) return false;
    items.add(a);
    notifyListeners();
    return true;
  }

  /// Avisos recibidos y todavía sin gestionar (R3). Simulado: todo aviso con
  /// recordatorio de una actividad pendiente cuenta como "recibido".
  List<Activity> get pendingReminders =>
      items.where((a) => a.reminderMinutes != null && !a.done && !a.acknowledged && a.raised).toList()
        ..sort((a, b) => a.when.compareTo(b.when));

  /// Simula la llegada del aviso de una actividad (sustituye a la notificación
  /// real del sistema en esta v1).
  void raiseReminder(Activity a) { a.raised = true; notifyListeners(); }

  void snooze(Activity a, int minutes) {
    final t = a.when.add(Duration(minutes: minutes));
    a.date = soloDia(t); a.hour = t.hour; a.minute = t.minute;
    a.acknowledged = true; a.raised = false;
    notifyListeners();
  }
}
