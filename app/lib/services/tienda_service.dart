import '../core/api_client.dart';
import '../models/tienda_model.dart';

class TiendaService {
  final ApiClient _api = ApiClient.instance;

  Future<List<ProductoModel>> obtenerProductos() async {
    final datos = await _api.get('/productos') as List<dynamic>;
    return datos
        .map((j) => ProductoModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<CarritoModel> obtenerCarrito() async {
    final datos = await _api.get('/carrito');
    return CarritoModel.fromJson(datos as Map<String, dynamic>);
  }

  /// Agrega el producto o cambia su cantidad.
  Future<CarritoModel> ponerEnCarrito(int productoId, int cantidad) async {
    final datos = await _api.put('/carrito/$productoId', body: {'cantidad': cantidad});
    return CarritoModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<CarritoModel> quitarDelCarrito(int productoId) async {
    final datos = await _api.delete('/carrito/$productoId');
    return CarritoModel.fromJson(datos as Map<String, dynamic>);
  }

  /// Pago simulado: la API valida la tarjeta y crea el pedido.
  Future<PedidoModel> pagar({
    required String titular,
    required String numero,
    required String expiracion,
    required String cvv,
  }) async {
    final datos = await _api.post('/pedidos/pagar', body: {
      'titular': titular.trim(),
      'numero': numero.replaceAll(' ', ''),
      'expiracion': expiracion.trim(),
      'cvv': cvv.trim(),
    });
    return PedidoModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<List<PedidoModel>> misPedidos() async {
    final datos = await _api.get('/pedidos') as List<dynamic>;
    return datos
        .map((j) => PedidoModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ---------- Validaciones de la tarjeta en la app ----------
  static bool luhnValido(String numero) {
    final digitos = numero.replaceAll(RegExp(r'\D'), '');
    if (digitos.length < 13 || digitos.length > 19) return false;
    var total = 0;
    for (var i = 0; i < digitos.length; i++) {
      var n = int.parse(digitos[digitos.length - 1 - i]);
      if (i.isOdd) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      total += n;
    }
    return total % 10 == 0;
  }

  static String? validarExpiracion(String? valor) {
    final v = (valor ?? '').trim();
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(v);
    if (m == null) return 'Usa el formato MM/AA';
    final mes = int.parse(m.group(1)!);
    final anio = 2000 + int.parse(m.group(2)!);
    if (mes < 1 || mes > 12) return 'Mes no válido';
    final hoy = DateTime.now();
    if (anio < hoy.year || (anio == hoy.year && mes < hoy.month)) return 'La tarjeta está vencida';
    return null;
  }
}
