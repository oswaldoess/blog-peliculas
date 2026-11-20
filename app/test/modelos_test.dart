// Pruebas de los modelos: verifican que la app interprete bien el JSON
// que regresa la API de FastAPI.  Ejecutar con:  flutter test

import 'package:flutter_test/flutter_test.dart';

import 'package:blog_peliculas/models/comentario_model.dart';
import 'package:blog_peliculas/models/post_model.dart';
import 'package:blog_peliculas/models/tienda_model.dart';
import 'package:blog_peliculas/services/tienda_service.dart';
import 'package:blog_peliculas/models/user_model.dart';
import 'package:blog_peliculas/utils/formatos.dart';

void main() {
  test('PostModel lee el JSON de /posts', () {
    final post = PostModel.fromJson({
      'id_blog': 3,
      'titulo': 'Una joya',
      'descripcion': 'palabra ' * 450,
      'pelicula': 'El laberinto del fauno',
      'anio': 2006,
      'genero': 'Fantasía',
      'img': '/static/uploads/abc.jpg',
      'tags': 'Fantasía oscura, Cine mexicano',
      'fecha': '2026-11-15T05:21:27+00:00',
      'actualizado': null,
      'autor': {'id_usr': 4, 'nom_usr': 'Andrea Ruiz'},
      'promedio': 5.0,
      'total_valoraciones': 2,
      'total_comentarios': 1,
      'mi_valoracion': null,
      'es_mio': false,
    });

    expect(post.peliculaConAnio, 'El laberinto del fauno (2006)');
    expect(post.tags, ['Fantasía oscura', 'Cine mexicano']);
    expect(post.autorNombre, 'Andrea Ruiz');
    expect(post.minutosLectura, 3);
    expect(post.imagenUrl, endsWith('/static/uploads/abc.jpg'));
    expect(post.imagenUrl, startsWith('http'));
  });

  test('UserModel calcula iniciales y rol', () {
    final u = UserModel.fromJson({
      'id_usr': 1,
      'nom_usr': 'Sofía Navarro',
      'tip_usu': 1,
      'creado_en': '2026-10-01T00:00:00+00:00',
    });
    expect(u.iniciales, 'SN');
    expect(u.esAdmin, isTrue);
    expect(u.rol, 'Administrador');
  });

  test('ComentarioModel trae reacciones', () {
    final c = ComentarioModel.fromJson({
      'id_com': 8,
      'comentario': '¡Buenísima!',
      'fecha': '2026-11-20T05:24:36+00:00',
      'blog_id': 2,
      'autor': {'id_usr': 2, 'nom_usr': 'Sofía'},
      'reacciones': [
        {'tipo': 'fire', 'total': 2, 'mia': true},
      ],
      'puede_borrar': true,
    });
    expect(c.reacciones.single.total, 2);
    expect(Reacciones.emoji(c.reacciones.single.tipo), '🔥');
  });

  test('Formatos relativos en español', () {
    final ahora = DateTime(2026, 11, 20, 12, 0);
    expect(Formatos.relativo(ahora.subtract(const Duration(minutes: 5)), ahora: ahora), 'hace 5 min');
    expect(Formatos.relativo(ahora.subtract(const Duration(hours: 3)), ahora: ahora), 'hace 3 h');
    expect(Formatos.relativo(ahora.subtract(const Duration(days: 1)), ahora: ahora), 'ayer');
    expect(Formatos.fecha(DateTime(2026, 11, 14)), '14 nov 2026');
  });

  test('Tienda: formato de precio y validación de tarjeta', () {
    expect(formatoPrecio(1234.5), '\$1,234.50');
    expect(formatoPrecio(79), '\$79.00');
    expect(TiendaService.luhnValido('4242 4242 4242 4242'), isTrue);
    expect(TiendaService.luhnValido('4242 4242 4242 4241'), isFalse);
    expect(TiendaService.validarExpiracion('13/30'), isNotNull);
    expect(TiendaService.validarExpiracion('12/99'), isNull);
  });
}
