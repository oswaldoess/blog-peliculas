class UserModel {
  static const int admin = 1;
  static const int autor = 2;

  final int id;
  final String nombre;
  final String? correo; // solo viene para el propio usuario o para un admin
  final String? ciudad;
  final String? bio;
  final int tipoUsuario;
  final bool activo;
  final DateTime? creadoEn;

  const UserModel({
    required this.id,
    required this.nombre,
    this.correo,
    this.ciudad,
    this.bio,
    this.tipoUsuario = autor,
    this.activo = true,
    this.creadoEn,
  });

  bool get esAdmin => tipoUsuario == admin;

  String get rol => esAdmin ? 'Administrador' : 'Autor';

  /// "Sofía Navarro" → "SN"
  String get iniciales {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id_usr'] as num).toInt(),
      nombre: json['nom_usr'] as String,
      correo: json['mail'] as String?,
      ciudad: json['dir_usr'] as String?,
      bio: json['bio'] as String?,
      tipoUsuario: (json['tip_usu'] as num?)?.toInt() ?? autor,
      activo: json['activo'] as bool? ?? true,
      creadoEn: json['creado_en'] == null
          ? null
          : DateTime.parse(json['creado_en'] as String).toLocal(),
    );
  }

  UserModel copyWith({
    String? nombre,
    String? correo,
    String? ciudad,
    String? bio,
    int? tipoUsuario,
    bool? activo,
  }) {
    return UserModel(
      id: id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      ciudad: ciudad ?? this.ciudad,
      bio: bio ?? this.bio,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      activo: activo ?? this.activo,
      creadoEn: creadoEn,
    );
  }
}
