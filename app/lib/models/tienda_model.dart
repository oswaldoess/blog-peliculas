class ProductoModel {
  final int id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final double precio;
  final int stock;
  final String? img;

  const ProductoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.precio,
    required this.stock,
    this.img,
  });

  bool get agotado => stock <= 0;

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      id: (json['id_prod'] as num).toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      categoria: json['categoria'] as String,
      precio: (json['precio'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      img: json['img'] as String?,
    );
  }
}

class CarritoItemModel {
  final ProductoModel producto;
  final int cantidad;
  final double subtotal;

  const CarritoItemModel({
    required this.producto,
    required this.cantidad,
    required this.subtotal,
  });

  factory CarritoItemModel.fromJson(Map<String, dynamic> json) {
    return CarritoItemModel(
      producto: ProductoModel.fromJson(json['producto'] as Map<String, dynamic>),
      cantidad: (json['cantidad'] as num).toInt(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

class CarritoModel {
  final List<CarritoItemModel> items;
  final int totalPiezas;
  final double total;

  const CarritoModel({required this.items, required this.totalPiezas, required this.total});

  static const CarritoModel vacio = CarritoModel(items: [], totalPiezas: 0, total: 0);

  int cantidadDe(int productoId) {
    for (final item in items) {
      if (item.producto.id == productoId) return item.cantidad;
    }
    return 0;
  }

  factory CarritoModel.fromJson(Map<String, dynamic> json) {
    return CarritoModel(
      items: (json['items'] as List<dynamic>)
          .map((j) => CarritoItemModel.fromJson(j as Map<String, dynamic>))
          .toList(),
      totalPiezas: (json['total_piezas'] as num).toInt(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class PedidoDetalleModel {
  final String nombre;
  final int cantidad;
  final double precioUnit;

  const PedidoDetalleModel({required this.nombre, required this.cantidad, required this.precioUnit});

  factory PedidoDetalleModel.fromJson(Map<String, dynamic> json) {
    return PedidoDetalleModel(
      nombre: json['nombre'] as String,
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnit: (json['precio_unit'] as num).toDouble(),
    );
  }
}

class PedidoModel {
  final int id;
  final double total;
  final String estado;
  final String referencia;
  final String marca;
  final String ultimos4;
  final DateTime fecha;
  final List<PedidoDetalleModel> detalles;

  const PedidoModel({
    required this.id,
    required this.total,
    required this.estado,
    required this.referencia,
    required this.marca,
    required this.ultimos4,
    required this.fecha,
    required this.detalles,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: (json['id_ped'] as num).toInt(),
      total: (json['total'] as num).toDouble(),
      estado: json['estado'] as String,
      referencia: json['referencia'] as String,
      marca: json['marca'] as String,
      ultimos4: json['ultimos4'] as String,
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      detalles: (json['detalles'] as List<dynamic>)
          .map((j) => PedidoDetalleModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// $1,234.50
String formatoPrecio(double valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final entero = partes[0];
  final buffer = StringBuffer();
  for (var i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buffer.write(',');
    buffer.write(entero[i]);
  }
  return '\$$buffer.${partes[1]}';
}
