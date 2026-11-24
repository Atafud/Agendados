import 'package:flutter/material.dart';
import 'model.dart';
import 'theme.dart';

/// Título de pantalla: marcado como encabezado para la navegación por títulos.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
      );
}

/// Opción de selección única (chip): estado nunca solo con color
/// (relleno + borde + marca ✓ + negrita) y nombre/estado semántico propios.
class Choice extends StatelessWidget {
  const Choice({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTarget, minWidth: kMinTarget),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? c.selectedBg : c.surface,
              border: Border.all(color: c.primary, width: selected ? 3 : 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (selected) ...[Icon(Icons.check, size: 20, color: c.text), const SizedBox(width: 4)],
              Flexible(child: Text(label, style: TextStyle(fontSize: 16, color: c.text,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500))),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Insignia de estado: icono + texto (nunca solo color).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.kind, {super.key});
  final String kind; // Hecha | Pendiente | Urgente
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    late IconData icon; late Color fg; late Color bg; late Color border;
    switch (kind) {
      case 'Hecha': icon = Icons.check_circle; fg = c.success; bg = c.successBg; border = c.success;
      case 'Urgente': icon = Icons.warning_amber_rounded; fg = c.urgent; bg = c.surface; border = c.urgent;
      default: icon = Icons.schedule; fg = c.text; bg = c.selectedBg; border = c.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 2), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: fg), const SizedBox(width: 4),
        Text(kind, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

/// Mensaje de error: icono "!" + texto en negrita + (en el campo) borde de 3 px.
/// Es una región activa, así que el lector de pantalla lo anuncia al aparecer.
class ErrorMessage extends StatelessWidget {
  const ErrorMessage(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Error: $text',
      excludeSemantics: true,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline, size: 20, color: c.error),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(color: c.error, fontWeight: FontWeight.w700, fontSize: 15))),
      ]),
    );
  }
}

/// Fila de actividad (P01). Dos controles separados: la casilla (marcar hecha,
/// una pulsación) y el cuerpo (abrir detalle). Cada uno es UN nodo semántico completo.
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.a, required this.onToggle, required this.onOpen});
  final Activity a;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  String get spoken => '${a.title}, ${a.timeText}, ${a.stateText}'
      '${a.urgent ? ', urgente' : ''}${a.reminderMinutes != null ? ', aviso ${a.reminderText}' : ''}';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: kGap),
      shape: RoundedRectangleBorder(side: BorderSide(color: c.primary, width: 2), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Widget estándar (Checkbox): aporta rol y estado; solo añadimos el nombre.
        Semantics(
          label: a.done ? 'Volver a dejar pendiente «${a.title}»' : 'Marcar «${a.title}» como hecha',
          child: SizedBox(
            width: kMinTarget + 8, height: kMinTarget + 8,
            child: Checkbox(value: a.done, onChanged: (_) => onToggle(),
                side: BorderSide(color: c.primary, width: 2), activeColor: c.success),
          ),
        ),
        Expanded(
          child: Semantics(
            button: true, container: true, label: '$spoken. Abrir detalle', excludeSemantics: true, onTap: onOpen,
            child: InkWell(
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kMinTarget + 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        decoration: a.done ? TextDecoration.lineThrough : null)),
                    Text(a.timeText, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      StatusBadge(a.done ? 'Hecha' : 'Pendiente'),
                      if (a.urgent) const StatusBadge('Urgente'),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
        ExcludeSemantics(child: Icon(Icons.chevron_right, color: c.primary)),
        const SizedBox(width: 8),
      ]),
    );
  }
}
