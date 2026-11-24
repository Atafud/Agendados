import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'model.dart';
import 'theme.dart';
import 'widgets.dart';

void _toggleActivityDone(AgendaModel model, Activity activity) {
  model.toggleDone(activity);
  if (activity.done) {
    HapticFeedback.lightImpact();
  }
}

/// Contenedor con navegación inferior estándar: Hoy / Avisos pendientes.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.model});
  final AgendaModel model;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final n = m.pendingReminders.length;
        return Scaffold(
          body: SafeArea(child: IndexedStack(index: tab, children: [AgendaScreen(model: m), PendingScreen(model: m)])),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: [
              const NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Hoy'),
              NavigationDestination(
                icon: Badge(isLabelVisible: n > 0, label: Text('$n'), child: const Icon(Icons.notifications_none)),
                selectedIcon: Badge(isLabelVisible: n > 0, label: Text('$n'), child: const Icon(Icons.notifications)),
                label: n > 0 ? 'Avisos pendientes ($n)' : 'Avisos pendientes',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── P01 Agenda / Hoy (R1, R2) ─────────────────────────
class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key, required this.model});
  final AgendaModel model;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final day = model.selected;
        final list = model.forDay(day);
        final isToday = mismoDia(day, model.today);
        return ListView(padding: const EdgeInsets.all(16), children: [
          const ScreenTitle('Agenda'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => model.shiftDay(-1),
                icon: const Icon(Icons.chevron_left), label: const Text('Anterior'))),
            const SizedBox(width: kGap),
            Expanded(child: OutlinedButton.icon(onPressed: () => model.shiftDay(1),
                icon: const Icon(Icons.chevron_right), label: const Text('Siguiente'), iconAlignment: IconAlignment.end)),
          ]),
          const SizedBox(height: kGap),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(model: model))),
            icon: const Icon(Icons.calendar_month), label: const Text('Elegir fecha en el calendario'),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true, liveRegion: true,
            child: Text('${isToday ? 'Hoy, ' : ''}${fechaLarga(day)}', style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(list.isEmpty ? 'Sin actividades' : '${list.length} ${list.length == 1 ? 'actividad' : 'actividades'}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditScreen(model: model))),
            icon: const Icon(Icons.add), label: const Text('Añadir actividad'),
          ),
          const SizedBox(height: 16),
          for (final a in list)
            ActivityCard(
              a: a,
              onToggle: () => _toggleActivityDone(model, a),
              onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(model: model, a: a))),
            ),
        ]);
      },
    );
  }
}

// ───────────────────────── P02 Calendario (R2) ─────────────────────────
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.model});
  final AgendaModel model;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime month = DateTime(widget.model.selected.year, widget.model.selected.month);
  late DateTime picked = widget.model.selected;

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final first = month;
    final offset = first.weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = <Widget>[];
    for (var i = 0; i < offset; i++) { cells.add(const SizedBox(height: kMinTarget)); }
    for (var d = 1; d <= days; d++) {
      final date = DateTime(month.year, month.month, d);
      final acts = m.forDay(date);
      final sel = mismoDia(date, picked);
      final urgent = acts.any((a) => a.urgent && !a.done);
      final label = '$d de ${fechaLarga(date).split(' de ').last}, '
          '${acts.isEmpty ? 'sin actividades' : '${acts.length} ${acts.length == 1 ? 'actividad' : 'actividades'}'}'
          '${urgent ? ', hay una urgente' : ''}${sel ? ', seleccionado' : ''}';
      cells.add(Semantics(
        button: true, selected: sel, label: label, excludeSemantics: true, onTap: () => setState(() => picked = date),
        child: InkWell(
          onTap: () => setState(() => picked = date),
          child: SizedBox(
            height: kMinTarget,
            child: Center(
              child: Container(
                width: 40, height: 40, // 40 visibles dentro de 48 táctiles (8 px de separación visual)
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.white,
                  border: Border.all(color: sel ? AppColors.text : AppColors.primary.withValues(alpha: 0.0), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Text('$d', style: TextStyle(fontSize: 16, fontWeight: acts.isEmpty ? FontWeight.w400 : FontWeight.w800,
                      color: sel ? Colors.white : AppColors.text)),
                  if (acts.isNotEmpty) Positioned(bottom: 3, child: Container(width: 16, height: 3, color: sel ? Colors.white : AppColors.primary)),
                  if (urgent) Positioned(top: 0, right: 2, child: Text('!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                      color: sel ? Colors.white : AppColors.urgent))),
                ]),
              ),
            ),
          ),
        ),
      ));
    }
    const wd = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final chunk = cells.sublist(i, i + 7 > cells.length ? cells.length : i + 7);
      while (chunk.length < 7) { chunk.add(const SizedBox(height: kMinTarget)); }
      rows.add(Row(children: [for (final c in chunk) Expanded(child: c)]));
    }
    final dayActs = m.forDay(picked);
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario'), leading: const BackButton()),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)),
                icon: const Icon(Icons.chevron_left), label: const Text('Mes anterior'))),
            const SizedBox(width: kGap),
            Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)),
                icon: const Icon(Icons.chevron_right), label: const Text('Mes siguiente'), iconAlignment: IconAlignment.end)),
          ]),
          const SizedBox(height: 12),
          Center(child: Semantics(header: true, liveRegion: true, child: Text(mesAnio(month), style: Theme.of(context).textTheme.titleMedium))),
          const SizedBox(height: 8),
          // La cabecera de letras es decorativa: cada celda ya anuncia su fecha completa.
          ExcludeSemantics(child: Row(children: [for (final w in wd) Expanded(child: Center(child: Text(w, style: Theme.of(context).textTheme.labelSmall)))])),
          ...rows,
          const SizedBox(height: 8),
          Text('Subrayado: tiene actividades · "!": hay una urgente', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 2), borderRadius: BorderRadius.circular(12)),
              child: Text('${fechaLarga(picked)}\n${dayActs.length} ${dayActs.length == 1 ? 'actividad' : 'actividades'}'
                  '${dayActs.any((a) => a.urgent) ? ' · 1 urgente' : ''}', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () { m.selectDay(picked); Navigator.pop(context); },
            child: const Text('Ver actividades de este día'),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── P03 Crear / Editar (R1) ─────────────────────────
class EditScreen extends StatefulWidget {
  const EditScreen({super.key, required this.model, this.editing});
  final AgendaModel model;
  final Activity? editing;
  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(text: widget.editing?.title ?? '');
  late final TextEditingController _time = TextEditingController(text: widget.editing?.timeText ?? '');
  late DateTime _date = widget.editing?.date ?? widget.model.selected;
  int? _reminder;
  bool _urgent = false;
  String _quick = '';

  @override
  void initState() {
    super.initState();
    _reminder = widget.editing?.reminderMinutes;
    _urgent = widget.editing?.urgent ?? false;
  }

  @override
  void dispose() { _title.dispose(); _time.dispose(); super.dispose(); }

  ({int h, int m})? _parse(String s) {
    final t = s.trim().replaceAll('.', ':');
    final r = RegExp(r'^(\d{1,2}):?(\d{2})$').firstMatch(t);
    if (r == null) return null;
    final h = int.parse(r.group(1)!), mi = int.parse(r.group(2)!);
    return (h >= 0 && h < 24 && mi >= 0 && mi < 60) ? (h: h, m: mi) : null;
  }

  void _quickDate(String key) {
    setState(() {
      _quick = key;
      final now = DateTime.now();
      if (key == 'Hoy') { _date = soloDia(now); }
      if (key == 'Mañana') { _date = soloDia(now.add(const Duration(days: 1))); }
      if (key == 'En 1 hora') {
        final t = now.add(const Duration(hours: 1));
        _date = soloDia(t); _time.text = hora(t.hour, t.minute);
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d != null) setState(() { _date = soloDia(d); _quick = ''; });
  }

  Future<void> _pickReminder() async {
    final r = await Navigator.push<int?>(context, MaterialPageRoute(builder: (_) => ReminderScreen(initial: _reminder)));
    if (!mounted) return;
    if (r != null) setState(() => _reminder = r == -1 ? null : r);
  }

  void _save() {
    if (!_form.currentState!.validate()) return; // los datos escritos se conservan
    final t = _time.text.trim().isEmpty ? (h: 9, m: 0) : _parse(_time.text)!;
    final title = _title.text.trim();
    final m = widget.model;
    final Activity a;
    if (widget.editing != null) {
      a = widget.editing!;
      a.title = title; a.date = _date; a.hour = t.h; a.minute = t.m; a.reminderMinutes = _reminder; a.urgent = _urgent;
      m.update();
    } else {
      a = m.add(title, _date, t.h, t.m, reminderMinutes: _reminder, urgent: _urgent);
      m.selectDay(_date);
    }
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Guardada: ${a.title}, ${fechaLarga(a.date)}, ${a.timeText}. ${a.reminderText}.'),
      duration: const Duration(seconds: 6),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar actividad' : 'Nueva actividad'), leading: const BackButton()),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
              controller: _title, textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Título (obligatorio)', hintText: 'Ej.: Entrega de práctica'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Falta el título. Escribe un nombre para la actividad.' : null,
              // Error accesible: icono + texto en negrita + borde de 3 px, anunciado como región activa.
              errorBuilder: (context, text) => ErrorMessage(text),
            ),
            const SizedBox(height: 16),
            Text('Fecha', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: kGap),
            Wrap(spacing: kGap, runSpacing: kGap, children: [
              Choice(label: 'Hoy', selected: _quick == 'Hoy', onTap: () => _quickDate('Hoy')),
              Choice(label: 'Mañana', selected: _quick == 'Mañana', onTap: () => _quickDate('Mañana')),
              Choice(label: 'En 1 hora', selected: _quick == 'En 1 hora', onTap: () => _quickDate('En 1 hora')),
            ]),
            const SizedBox(height: kGap),
            _FieldRow(icon: Icons.calendar_today, name: 'Fecha', value: fechaLarga(_date), onTap: _pickDate),
            const SizedBox(height: 16),
            TextFormField(
              controller: _time, keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(labelText: 'Hora (HH:MM, opcional)', hintText: '14:35'),
              validator: (v) => (v == null || v.trim().isEmpty || _parse(v) != null)
                  ? null : 'La hora no es válida. Escríbela así: 14:35.',
              errorBuilder: (context, text) => ErrorMessage(text),
            ),
            const SizedBox(height: 16),
            _FieldRow(icon: Icons.notifications_active_outlined, name: 'Recordatorio',
                value: _reminder == null ? 'Sin aviso' : (_reminder == 0 ? 'A la hora' : '$_reminder minutos antes'), onTap: _pickReminder),
            const SizedBox(height: kGap),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero, value: _urgent, onChanged: (v) => setState(() => _urgent = v ?? false),
              title: const Text('Marcar como urgente'), controlAffinity: ListTileControlAffinity.leading,
              side: const BorderSide(color: AppColors.primary, width: 2),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Guardar actividad')),
            const SizedBox(height: kGap),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ]),
        ),
      ),
    );
  }
}

/// Fila-botón con borde, valor actual y flecha: no parece texto plano (hallazgo P-01).
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.icon, required this.name, required this.value, required this.onTap});
  final IconData icon; final String name; final String value; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true, label: '$name: $value. Cambiar', excludeSemantics: true, onTap: onTap,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTarget + 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 2), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(icon, color: AppColors.primary), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: Theme.of(context).textTheme.labelSmall),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ])),
                const Icon(Icons.chevron_right, color: AppColors.primary),
              ]),
            ),
          ),
        ),
      );
}

// ───────────────────────── P04 Configurar recordatorio (R1) ─────────────────────────
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key, this.initial});
  final int? initial;
  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late int? value = widget.initial;
  static const options = <(int?, String)>[
    (null, 'Sin aviso'), (0, 'A la hora'), (10, '10 minutos antes'), (30, '30 minutos antes'),
    (60, '1 hora antes'), (1440, '1 día antes'),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Recordatorio'), leading: const BackButton()),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const ScreenTitle('¿Cuándo quieres el aviso?'),
            const SizedBox(height: kGap),
            RadioGroup<int?>(
              groupValue: value, onChanged: (v) => setState(() => value = v),
              child: Column(children: [
                for (final o in options)
                  RadioListTile<int?>(value: o.$1, title: Text(o.$2, style: TextStyle(fontSize: 16,
                      fontWeight: value == o.$1 ? FontWeight.w800 : FontWeight.w400)), contentPadding: EdgeInsets.zero),
              ]),
            ),
            const SizedBox(height: 16),
            // -1 = "sin aviso" (distingue de volver atrás sin aceptar, que devuelve null).
            FilledButton(onPressed: () => Navigator.pop(context, value ?? -1), child: const Text('Aceptar recordatorio')),
          ]),
        ),
      );
}

// ───────────────────────── P05 Detalle (R2, R3) ─────────────────────────
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.model, required this.a});
  final AgendaModel model;
  final Activity a;

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar «${a.title}»?'),
        content: const Text('La actividad desaparecerá de tu agenda. Podrás deshacerlo justo después.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    model.remove(a);
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text('Eliminada: ${a.title}'), duration: const Duration(seconds: 8),
      action: SnackBarAction(label: 'Deshacer', onPressed: model.undoRemove),
    ));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: model,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Detalle'), leading: const BackButton()),
          body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              ScreenTitle(a.title),
              const SizedBox(height: kGap),
              // Un único bloque de lectura con todos los datos.
              MergeSemantics(child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 2), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${fechaLarga(a.date)}, ${a.timeText}', style: Theme.of(context).textTheme.bodyLarge),
                  Text('Aviso: ${a.reminderText}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    StatusBadge(a.done ? 'Hecha' : 'Pendiente'),
                    if (a.urgent) const StatusBadge('Urgente'),
                  ]),
                ]),
              )),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _toggleActivityDone(model, a),
                icon: Icon(a.done ? Icons.undo : Icons.check),
                label: Text(a.done ? 'Volver a dejar pendiente' : 'Marcar como hecha'),
              ),
              const SizedBox(height: 16),
              Text('Posponer el aviso', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: kGap),
              Wrap(spacing: kGap, runSpacing: kGap, children: [
                for (final min in const [10, 60, 1440])
                  OutlinedButton(
                    onPressed: () { model.snooze(a, min); ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Pospuesta a ${fechaLarga(a.date)}, ${a.timeText}'))); },
                    child: Text(min == 10 ? 'Posponer 10 minutos' : min == 60 ? 'Posponer 1 hora' : 'Posponer 1 día'),
                  ),
              ]),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditScreen(model: model, editing: a))),
                icon: const Icon(Icons.edit), label: const Text('Editar'),
              ),
              const SizedBox(height: 16), // separación mayor antes de la acción destructiva
              OutlinedButton.icon(
                onPressed: () => _delete(context),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error, width: 2)),
                icon: const Icon(Icons.delete_outline), label: const Text('Eliminar'),
              ),
            ]),
          ),
        ),
      );
}

// ───────────────────────── P06 Avisos pendientes (R3) ─────────────────────────
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key, required this.model});
  final AgendaModel model;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final list = model.pendingReminders;
          final candidates = model.items.where((a) => a.reminderMinutes != null && !a.done && !a.raised).toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            const ScreenTitle('Avisos pendientes'),
            const SizedBox(height: 12),
            if (list.isEmpty) Text('No tienes avisos pendientes.', style: Theme.of(context).textTheme.bodyLarge),
            for (final a in list)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(side: const BorderSide(color: AppColors.primary, width: 2), borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MergeSemantics(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('${fechaLarga(a.date)}, ${a.timeText} · Aviso: ${a.reminderText}', style: Theme.of(context).textTheme.bodyMedium),
                    ])),
                    const SizedBox(height: kGap),
                    Wrap(spacing: kGap, runSpacing: kGap, children: [
                      FilledButton(
                        onPressed: () => _toggleActivityDone(model, a),
                        child: Text('Hecha: ${a.title}', maxLines: 2),
                      ),
                      OutlinedButton(onPressed: () => model.snooze(a, 10), child: Text('Posponer 10 minutos: ${a.title}', maxLines: 2)),
                      OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(model: model, a: a))),
                        child: const Text('Abrir aviso'),
                      ),
                    ]),
                  ]),
                ),
              ),
            if (candidates.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Demostración (v1): en la app real el aviso llega como notificación del sistema.',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: kGap),
              OutlinedButton(onPressed: () => model.raiseReminder(candidates.first),
                  child: Text('Simular aviso de «${candidates.first.title}»')),
            ],
          ]);
        },
      );
}
