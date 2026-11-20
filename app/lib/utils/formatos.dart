/// Formatos de fecha en español sin depender de paquetes extra.
class Formatos {
  Formatos._();

  static const List<String> _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  static String _dos(int n) => n.toString().padLeft(2, '0');

  /// 14 nov 2026
  static String fecha(DateTime d) => '${d.day} ${_meses[d.month - 1]} ${d.year}';

  /// 18:05
  static String hora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

  /// "hace 5 min", "hace 3 h", "ayer", "14 nov 2026"
  static String relativo(DateTime d, {DateTime? ahora}) {
    final ref = ahora ?? DateTime.now();
    final diff = ref.difference(d);
    if (diff.inSeconds < 60) return 'justo ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return fecha(d);
  }

  /// Para la lista de chats: hora si es de hoy, fecha corta si no.
  static String chat(DateTime d, {DateTime? ahora}) {
    final ref = ahora ?? DateTime.now();
    final mismoDia = d.year == ref.year && d.month == ref.month && d.day == ref.day;
    if (mismoDia) return hora(d);
    return '${d.day} ${_meses[d.month - 1]}';
  }
}
