import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/navegacion.dart';
import '../models/tienda_model.dart';
import '../services/tienda_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/estado_vista.dart';
import 'carrito_page.dart';

/// Catálogo de productos (módulo de venta y comercio electrónico).
class TiendaPage extends StatefulWidget {
  const TiendaPage({super.key});

  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

class _TiendaPageState extends State<TiendaPage> {
  final _servicio = TiendaService();

  List<ProductoModel> _productos = [];
  CarritoModel _carrito = CarritoModel.vacio;
  String? _categoria;
  bool _cargando = true;
  Object? _error;
  int? _agregando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultados = await Future.wait([
        _servicio.obtenerProductos(),
        _servicio.obtenerCarrito(),
      ]);
      if (!mounted) return;
      setState(() {
        _productos = resultados[0] as List<ProductoModel>;
        _carrito = resultados[1] as CarritoModel;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _agregar(ProductoModel p) async {
    setState(() => _agregando = p.id);
    try {
      final carrito = await _servicio.ponerEnCarrito(p.id, _carrito.cantidadDe(p.id) + 1);
      if (!mounted) return;
      setState(() => _carrito = carrito);
      mostrarMensaje('${p.nombre} agregado al carrito');
    } catch (e) {
      mostrarMensaje(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _agregando = null);
    }
  }

  Future<void> _abrirCarrito() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CarritoPage()),
    );
    _cargar(); // pudo pagar o cambiar cantidades
  }

  @override
  Widget build(BuildContext context) {
    final categorias = _productos.map((p) => p.categoria).toSet().toList()..sort();
    final visibles = _categoria == null
        ? _productos
        : _productos.where((p) => p.categoria == _categoria).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: [
          IconButton(
            tooltip: 'Carrito',
            onPressed: _abrirCarrito,
            icon: Badge(
              isLabelVisible: _carrito.totalPiezas > 0,
              label: Text('${_carrito.totalPiezas}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _cuerpo(categorias, visibles),
      ),
    );
  }

  Widget _cuerpo(List<String> categorias, List<ProductoModel> visibles) {
    if (_cargando && _productos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _productos.isEmpty) {
      return EstadoVista.error(_error!, _cargar);
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tienda del cinéfilo', style: AppTheme.titulo(size: 28)),
        const SizedBox(height: 5),
        const Text('Artículos para tus maratones', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  text: 'Todos',
                  selected: _categoria == null,
                  onTap: () => setState(() => _categoria = null),
                ),
              ),
              ...categorias.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    text: c,
                    selected: _categoria == c,
                    onTap: () => setState(() => _categoria = c),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...visibles.map((p) => _TarjetaProducto(
              producto: p,
              enCarrito: _carrito.cantidadDe(p.id),
              agregando: _agregando == p.id,
              alAgregar: () => _agregar(p),
            )),
      ],
    );
  }
}

/// Ícono según la categoría del producto (no se usan imágenes con derechos).
IconData iconoCategoria(String categoria) {
  switch (categoria) {
    case 'Ropa':
      return Icons.checkroom;
    case 'Regalos':
      return Icons.card_giftcard;
    case 'Decoración':
      return Icons.lightbulb_outline;
    case 'Papelería':
      return Icons.menu_book;
    default:
      return Icons.local_movies;
  }
}

class _TarjetaProducto extends StatelessWidget {
  final ProductoModel producto;
  final int enCarrito;
  final bool agregando;
  final VoidCallback alAgregar;

  const _TarjetaProducto({
    required this.producto,
    required this.enCarrito,
    required this.agregando,
    required this.alAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final sinStock = p.agotado || enCarrito >= p.stock;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.azul.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconoCategoria(p.categoria), size: 38, color: AppColors.azul),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.categoria.toUpperCase(),
                    style: const TextStyle(color: AppColors.azul, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.nombre,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.marino),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        formatoPrecio(p.precio),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.agotado ? 'Agotado' : '${p.stock} disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          color: p.agotado ? AppColors.rojo : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (agregando)
                        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        IconButton.filled(
                          tooltip: 'Agregar al carrito',
                          onPressed: sinStock ? null : alAgregar,
                          icon: Badge(
                            isLabelVisible: enCarrito > 0,
                            label: Text('$enCarrito'),
                            child: const Icon(Icons.add_shopping_cart),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
